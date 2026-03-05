# Terraform — Day 12 Secure Network Architecture

## Structure
```
terraform/
├── main.tf          ← Root module: wires all 4 modules together
├── variables.tf     ← All input variables with defaults
├── outputs.tf       ← Outputs: private IPs, resource IDs, DNS info
├── providers.tf     ← AzureRM provider + OIDC auth config
├── backend.tf       ← Remote state config (values injected by pipeline)
└── modules/
    ├── networking/          ← Hub VNet, Spoke VNet, Subnets, Peering, NSG
    ├── storage/             ← Storage Account, public access disabled
    ├── keyvault/            ← Key Vault, public access disabled
    └── private-endpoints/   ← Private Endpoints + Private DNS Zones
```

---

## How Modules Connect
```
main.tf
  │
  ├── module.networking   → creates RG, Hub VNet, Spoke VNet, subnets, NSGs
  │        │
  │        └── outputs: resource_group_name, hub_vnet_id,
  │                      spoke_vnet_id, pe_subnet_id
  │
  ├── module.storage      → uses resource_group_name from networking
  │        └── outputs: storage_account_id, storage_account_name
  │
  ├── module.keyvault     → uses resource_group_name from networking
  │        └── outputs: key_vault_id, key_vault_name
  │
  └── module.private_endpoints
           → uses pe_subnet_id, hub_vnet_id, spoke_vnet_id from networking
           → uses storage_account_id from storage
           → uses key_vault_id from keyvault
```

---

## Variables You Must Set

These have no defaults — must come from pipeline variable group:

| Variable | Where to get it |
|---|---|
| `client_id` | Azure App Registration → Application (client) ID |
| `tenant_id` | Azure App Registration → Directory (tenant) ID |
| `subscription_id` | Azure Portal → Subscriptions |

---

## Running Locally (for debugging only)
```powershell
# Step 1 — initialise with remote backend
terraform init `
  -backend-config="resource_group_name=rg-day11-tfstate" `
  -backend-config="storage_account_name=stday11tfstate7771" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=day12.terraform.tfstate"

# Step 2 — validate
terraform validate

# Step 3 — plan
terraform plan `
  -var="client_id=<your-client-id>" `
  -var="tenant_id=<your-tenant-id>" `
  -var="subscription_id=<your-subscription-id>"
```

> Normal workflow is via Azure DevOps pipeline — not local.
> Local runs are only for debugging Terraform code errors.

---

## Key Design Decisions

**Why `depends_on` on every module?**
Terraform can try to create private endpoints before storage
is fully ready. depends_on forces: networking → storage/keyvault
→ private endpoints.

**Why empty backend.tf?**
No hardcoded values — all backend config is injected at runtime
by the pipeline via -backend-config flags. Safe to commit to git.

**Why purge_soft_delete_on_destroy = true on Key Vault?**
Without this, terraform destroy fails because Key Vault soft-delete
holds the name for 90 days blocking recreation.