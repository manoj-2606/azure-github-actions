# Day 11 — Identity, RBAC & Zero-Trust Infrastructure

> Most engineers assign Contributor at subscription level and call it done. It works. It is also a security liability waiting to be exploited. Day 11 breaks that habit.

---

## Why This Day Exists

Days 1 through 10 focused on building infrastructure — resource groups, networks, storage, Key Vaults. You could create things. But every resource you created was accessible to whoever had the right role, and that role was probably too broad.

Day 11 answers the question every security-conscious employer will ask you: "How do you control who can do what in your Azure environment?"

The answer is not "I assigned Contributor to my service principal." The answer is a documented, code-reviewed, version-controlled identity and access model where every identity has a reason, every role has a scope, and no permission is broader than necessary.

This is how infrastructure is built at companies operating under ISO 27001, SOC 2, GDPR, PCI-DSS, or any EU regulatory framework. Finnish companies in finance, healthcare, and SaaS all require this. Day 11 is where you learn to think like a security engineer, not just a DevOps engineer.

---

## What You Built

All resources deployed to Central India inside `rg-day11-identity`.

```
┌──────────────────────────────────────────────────────────────────┐
│                     AZURE SUBSCRIPTION                           │
│                                                                  │
│  ┌───────────────────────────┐  ┌────────────────────────────┐  │
│  │   rg-day11-tfstate        │  │   rg-day11-identity        │  │
│  │                           │  │                            │  │
│  │   stday11tfstateXXXXX     │  │   id-day11-app (UAMI)      │  │
│  │   └─ tfstate container    │  │   stday11app001            │  │
│  │      └─ day11.tfstate     │  │   kv-day11-001             │  │
│  └───────────────────────────┘  │                            │  │
│                                 │   Role Assignments:        │  │
│                                 │   UAMI → Blob Contributor  │  │
│                                 │   UAMI → Reader (RG)       │  │
│                                 │   UAMI → KV Secrets User   │  │
│                                 └────────────────────────────┘  │
│                                                                  │
│  Pipeline SP:                                                    │
│  Contributor → rg-day11-identity only                            │
│  User Access Admin → rg-day11-identity only                      │
└──────────────────────────────────────────────────────────────────┘
```

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | `rg-day11-identity` | All application resources |
| Resource Group | `rg-day11-tfstate` | Isolated state storage — never destroyed |
| Storage Account | `stday11tfstateXXXXX` | Terraform remote state backend |
| Storage Account | `stday11app001` | Application storage for RBAC exercise |
| User-Assigned Managed Identity | `id-day11-app` | Workload identity — no passwords |
| Key Vault | `kv-day11-001` | Secret store with RBAC authorization |
| Role Assignment | Storage Blob Data Contributor | Identity → Storage Account scope only |
| Role Assignment | Reader | Identity → Resource Group scope only |
| Role Assignment | Key Vault Secrets User | Identity → Key Vault scope only |

---

## Folder Structure

```
Day11/
├── main.tf                       # Root — wires all modules together
├── providers.tf                  # AzureRM provider + remote backend config
├── variables.tf                  # Input variable declarations
├── terraform.tfvars              # Actual values — never committed to git
├── outputs.tf                    # principal_id, client_id, KV URI, role summary
├── modules/
│   ├── identity/                 # Creates User-Assigned Managed Identity
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rbac/                     # Creates role assignments via for_each
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── keyvault/                 # Creates Key Vault in RBAC mode
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── pipeline/
    └── azure-pipelines.yml       # Validate → Plan → Apply with OIDC
```

---

## Remote Backend — Why Two Resource Groups

You created two resource groups before writing a single Terraform resource. This is intentional and the reason matters.

`rg-day11-tfstate` holds the storage account for Terraform state. It is kept completely separate from `rg-day11-identity` which holds your application resources. The consequence of this separation is that you can run `terraform destroy` on `rg-day11-identity` — wiping everything you built today — and your state file survives in `rg-day11-tfstate`. Your next apply starts from a known state, not from scratch guessing what exists.

If both lived in the same resource group and you deleted that group in the portal, your state file would be gone. Terraform would have no record of what it managed and your next apply would try to create duplicate resources, hitting name conflicts and failing.

Remote state in a dedicated, isolated resource group is not overhead. It is the foundation that makes every pipeline run safe.

**The bootstrap commands — run once, never again:**
```bash
az group create --name rg-day11-tfstate --location centralindia
az storage account create --name stday11tfstateXXXXX --resource-group rg-day11-tfstate --location centralindia --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --name tfstate --account-name stday11tfstateXXXXX --auth-mode login
az group create --name rg-day11-identity --location centralindia
```

---

## Step-by-Step — What You Did and Why

---

### Step 1 — Backend Bootstrap

**Why this step exists:**
Before Terraform can store state remotely, the storage account must exist. You cannot point a backend at something that does not yet exist. This is the bootstrap problem of remote state — solved by creating the storage account manually via az cli before Terraform runs for the first time.

`--auth-mode login` on the container create command uses Azure AD authentication instead of storage account keys. This matters. Storage account keys are long-lived credentials that never expire unless manually rotated. Azure AD tokens expire automatically. Using `--auth-mode login` means you never interact with the account keys during bootstrap.

`--allow-blob-public-access false` ensures no blob in this storage account can ever be made publicly accessible. Your Terraform state contains resource IDs, IP addresses, and sometimes sensitive values. It must never be publicly readable.

---

### Step 2 — Identity Module — Managed Identity

**Why this step exists:**
A Managed Identity is an Azure Active Directory identity with no password, no client secret, and no expiry date. Azure manages the credential lifecycle automatically. Your application never stores a secret. There is nothing to rotate, nothing to leak, and nothing to expire at 3am before a critical deployment.

Understanding the difference between the two types is critical:

**User-Assigned Managed Identity** — what you built. Lives independently of any single resource. You can attach it to multiple VMs, App Services, or containers. If a resource is deleted, the identity survives and retains its role assignments. Use this when one identity needs to work across multiple resources or when you need the identity to outlive the resources it is attached to.

**System-Assigned Managed Identity** — tied to one resource. Created when the resource is created. Destroyed when the resource is destroyed. Simpler for single-resource scenarios but inflexible. If the VM is deleted and recreated, it gets a new identity and loses all its role assignments.

The key insight: **identity is not access**. Creating the managed identity does nothing on its own. It is just "who you are." What you can do is determined entirely by the role assignments in the next step.

The module outputs `principal_id` and `client_id`. The `principal_id` is used for role assignments — it identifies the identity in Azure AD. The `client_id` is used for authentication — it identifies the application registration. Both are needed downstream.

---

### Step 3 — RBAC Module — Role Assignments with for_each

**Why this step exists:**
This is the core skill of Day 11. Role assignments are how Azure RBAC works — they connect an identity (who), a role (what permissions), and a scope (where those permissions apply).

If you write one `azurerm_role_assignment` block per role, you have three blocks for three roles. When you need to add a fourth role, you write a fourth block. When you need to remove one, you find and delete the right block. In a large environment with hundreds of roles, this is unmanageable.

The `for_each` pattern solves this. Roles are defined as a map variable. The module iterates the map and creates one role assignment per entry. Adding a new role is one line in the variable definition. Removing a role is deleting one line. The logic never changes.

```hcl
variable "role_assignments" {
  type = map(object({
    role_definition_name = string
    scope                = string
  }))
}
```

Called with:
```hcl
role_assignments = {
  blob_contributor = {
    role_definition_name = "Storage Blob Data Contributor"
    scope                = azurerm_storage_account.app.id
  }
  rg_reader = {
    role_definition_name = "Reader"
    scope                = azurerm_resource_group.main.id
  }
  kv_secrets_user = {
    role_definition_name = "Key Vault Secrets User"
    scope                = module.keyvault.key_vault_id
  }
}
```

The key named `blob_contributor` in the map becomes the `for_each` key in state. If you remove it from the map, Terraform destroys only that assignment. The others are untouched. This is why `for_each` with meaningful keys is always preferred over `count` for role assignments — `count` uses numeric indices and removing index 1 from a list of 3 causes Terraform to destroy index 1 and rename indexes 2 and 3, triggering unnecessary churn.

**Scoping hierarchy — this is where most engineers get it wrong:**
```
Subscription          ← widest, almost never correct
  └── Resource Group  ← reasonable default
        └── Resource  ← preferred for specific access
```

Every role assignment in Day 11 is scoped to the tightest level that still works. Blob access is scoped to the storage account — not the resource group, not the subscription. Key Vault access is scoped to that specific vault. Reader access is scoped to the resource group because the identity needs to see multiple resources inside it. If the blob contributor role were scoped to the subscription, the identity could read and write blobs in every storage account across your entire Azure environment. That is not least privilege. That is a breach waiting to happen.

---

### Step 4 — Key Vault with RBAC Authorization Model

**Why this step exists:**
Azure Key Vault has two permission models and the difference is fundamental.

**Access Policies (legacy):** Permissions are stored inside the vault itself as a property of the resource. You manage them separately from every other Azure permission. They cannot be audited by Azure Policy. They do not show up in the unified RBAC role assignments list. They are inconsistent with everything else in Azure.

**RBAC model (modern):** Permissions are standard Azure role assignments — the same system used for every other resource. They are auditable, consistent, manageable via Terraform in the same module as your other role assignments, and visible in the unified Access Control blade across Azure.

```hcl
enable_rbac_authorization = true
```

This single line switches the vault from Access Policies to RBAC mode. Once enabled, Access Policies no longer work. Any existing access policy grants are ignored. All access must be through role assignments.

The role assigned is `Key Vault Secrets User` — not `Key Vault Secrets Officer`, not `Key Vault Administrator`. `Secrets User` grants read access to secrets. Nothing more. The managed identity can read the secrets it needs to operate. It cannot create new secrets, delete secrets, or manage the vault itself. This is least privilege applied at the role selection level, not just the scope level.

---

### Step 5 — Pipeline Least Privilege

**Why this step exists:**
A pipeline service principal with Contributor at subscription level can create, modify, and delete any resource in your entire Azure subscription. If that service principal's credentials are compromised, your entire Azure environment is exposed. If a bug in your Terraform code targets the wrong resource group, it can destroy production resources in a different project.

Day 11 scopes the pipeline SP to `rg-day11-identity` only. Contributor at that scope means the pipeline can create and manage resources inside that resource group and nowhere else. A bug cannot escape the boundary.

But Contributor alone is insufficient for Day 11. Creating role assignments requires `Microsoft.Authorization/roleAssignments/write` — a permission not included in Contributor. You added `User Access Administrator` scoped to the same resource group to provide exactly that permission.

```bash
az role assignment create --assignee YOUR_SP_OBJECT_ID --role "User Access Administrator" --scope "/subscriptions/YOUR_SUB_ID/resourceGroups/rg-day11-identity"
```

The two roles together give the pipeline what it needs:
- `Contributor` → create and manage resources inside the RG
- `User Access Administrator` → create role assignments inside the RG

Nothing more. The pipeline cannot touch any other resource group, cannot make role assignments at subscription level, and cannot modify resources outside its explicit scope.

**What you never assign to a pipeline:**
- `Owner` anywhere — Owner includes User Access Administrator plus Contributor, subscription-wide
- `Contributor` at subscription — no boundary, full resource access everywhere
- `Owner` at subscription — effectively full control of your Azure account

---

### Step 6 — OIDC Pipeline Authentication

**Why this step exists:**
Traditional pipeline authentication uses a client secret — a password stored in Azure DevOps pipeline variables. That secret has an expiry date. Someone must rotate it. If it appears in a pipeline log, is committed to git, or is accessed by a disgruntled team member, an attacker has persistent access to your Azure subscription until you discover it and revoke it.

OIDC eliminates the secret entirely. Azure DevOps generates a short-lived JWT token at pipeline runtime. Terraform exchanges this token with Azure AD for an access token. The JWT is valid for minutes. There is no password stored anywhere — not in ADO variables, not in code, not in environment variables that persist between runs.

The environment variables that make OIDC work:
- `ARM_USE_OIDC=true` — tells the AzureRM provider to use token exchange instead of password auth
- `ARM_OIDC_TOKEN=$idToken` — the JWT generated by ADO, injected via `addSpnToEnvironment: true`
- `ARM_CLIENT_ID` — which service principal to authenticate as
- `ARM_TENANT_ID` — which Azure AD tenant to trust

If `ARM_OIDC_TOKEN` is missing or stale, Terraform falls back to CLI auth, which fails for service principals in a pipeline context. This is why the OIDC token must be explicitly set — it does not flow automatically without the `addSpnToEnvironment` configuration.

---

## Pipeline Flow

```
Push to main branch
        │
        ▼
┌─────────────────────────────────────┐
│  VALIDATE stage                     │
│  terraform fmt -check -recursive    │
│  terraform validate                 │
└────────────────┬────────────────────┘
                 │ success
                 ▼
┌─────────────────────────────────────┐
│  PLAN stage                         │
│  terraform plan -out=tfplan.binary  │
│  terraform show → tfplan.txt        │
│  publish artifact: tfplan.binary    │
└────────────────┬────────────────────┘
                 │ success + branch = main
                 ▼
┌─────────────────────────────────────┐
│  APPLY stage                        │
│  download artifact: tfplan.binary   │
│  terraform apply -auto-approve      │
│  terraform output                   │
└─────────────────────────────────────┘
```

The plan binary is published as a pipeline artifact and downloaded by the Apply stage. This guarantees Apply executes the exact same plan that was reviewed — no re-planning between stages, no surprise changes introduced by a resource that was modified in Azure between plan and apply.

`terraform show -no-color tfplan.binary > tfplan.txt` converts the binary to human-readable text and saves it as an artifact. This is your audit trail — anyone can open the artifact and read exactly what Terraform intended to do before it did it.

---

## Least Privilege Audit

| Identity | Role | Scope | Why This Scope |
|---|---|---|---|
| `id-day11-app` | Storage Blob Data Contributor | `stday11app001` only | Needs blob access to one account, not all storage |
| `id-day11-app` | Reader | `rg-day11-identity` only | Needs to see resources in the RG, not the subscription |
| `id-day11-app` | Key Vault Secrets User | `kv-day11-001` only | Needs to read secrets from one vault, not all vaults |
| Pipeline SP | Contributor | `rg-day11-identity` only | Creates resources in this RG, cannot touch others |
| Pipeline SP | User Access Administrator | `rg-day11-identity` only | Creates role assignments in this RG only |

**What nothing has:**
- Owner at any scope
- Contributor at subscription scope
- Any role at subscription scope

---

## Rules Enforced Throughout

```
No Owner role assignments
No subscription-scope Contributor
No hardcoded secrets anywhere
No manual portal role assignments
Everything is code
Every role has a documented reason
Least privilege at every scope level
```

---

## Concepts You Can Now Answer

**Managed Identity vs Service Principal:**
A Service Principal is an identity with a client secret or certificate — you manage the credential. A Managed Identity is an identity where Azure manages the credential. You never see the secret. It never expires unless you delete the identity. For workloads running in Azure, Managed Identity is always preferred over Service Principal with secrets.

**User-Assigned vs System-Assigned:**
System-Assigned dies with the resource it is attached to. User-Assigned lives independently and survives resource deletion. Use User-Assigned when the identity must persist, when it needs to be attached to multiple resources, or when role assignments must survive infrastructure rebuilds.

**Why `for_each` over `count` for role assignments:**
`count` uses numeric index keys. Removing an item from the middle of a list shifts all subsequent indices and causes unnecessary destroy-and-recreate cycles. `for_each` with named keys only destroys the specific entry removed. For role assignments this is critical — a destroy-recreate on a role assignment causes a window of no access between the destroy and recreate completing.

**RBAC model vs Access Policies in Key Vault:**
Access Policies are stored inside the vault and cannot be audited by Azure Policy. RBAC model uses standard Azure role assignments — consistent, auditable, and manageable in the same Terraform module as all other permissions. Modern Key Vault deployments always use RBAC model.

**Why the pipeline SP needs User Access Administrator:**
The `Contributor` role does not include `Microsoft.Authorization/roleAssignments/write`. Without it, Terraform cannot create role assignments — it gets a 403 on the role assignment API. `User Access Administrator` adds exactly that permission, scoped to the resource group, allowing Terraform to manage role assignments inside that boundary only.

**Why OIDC eliminates a class of security risk:**
Client secrets have three failure modes — they expire and break pipelines, they get committed to code repositories accidentally, and they can be extracted from pipeline logs if not properly masked. OIDC tokens have none of these failure modes. They are generated per run, valid for minutes, and cannot be reused. There is nothing to store and therefore nothing to steal.

---

## Real-World Application

This exact pattern is used in production by:

**Financial services** — Every microservice has its own managed identity scoped to exactly the resources it needs. Role assignments are reviewed in pull requests. No human ever clicks in the portal to grant access.

**Healthcare platforms** — HIPAA and Finnish healthcare regulations require documented audit trails for all access changes. RBAC as code provides this through git history and pipeline deployment logs automatically.

**SaaS companies in EU** — Applications on App Service, AKS, or Container Apps authenticate to Key Vault and Storage using managed identities. No secrets in environment variables. No rotation schedules. No leaked credentials in git history.

**GDPR compliance** — Article 32 requires technical measures demonstrating appropriate access control. Terraform state plus git history plus ADO deployment logs plus Azure Activity Logs equals a complete, demonstrable, auditable access control record.

---

## How to Deploy

**Backend bootstrap — run once only:**
```bash
az group create --name rg-day11-tfstate --location centralindia
az storage account create --name YOUR_UNIQUE_NAME --resource-group rg-day11-tfstate --location centralindia --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --name tfstate --account-name YOUR_UNIQUE_NAME --auth-mode login
az group create --name rg-day11-identity --location centralindia
```

**Grant pipeline SP permission to create role assignments:**
```bash
az role assignment create --assignee YOUR_SP_OBJECT_ID --role "User Access Administrator" --scope "/subscriptions/YOUR_SUB_ID/resourceGroups/rg-day11-identity"
```

**Deploy via pipeline:**
```bash
git add Terraform/Day11/ && git commit -m "day11: identity, rbac, and zero-trust infrastructure" && git push origin main
```

**Verify after apply:**
```bash
az identity list --resource-group rg-day11-identity --output table
az role assignment list --resource-group rg-day11-identity --output table
az keyvault show --name kv-day11-001 --resource-group rg-day11-identity --query properties.enableRbacAuthorization
```