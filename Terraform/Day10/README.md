# azure-secure-foundation-iac

> Production-grade Azure Infrastructure · Terraform · OIDC · Azure DevOps · Multi-environment

---

## Folder Structure

```
azure-secure-foundation-iac/
 ├─ terraform/
 │   ├─ modules/
 │   │   ├─ networking/      VNet + Subnets + NSGs (dynamic rules)
 │   │   ├─ storage/         Storage Account + lifecycle policy
 │   │   ├─ keyvault/        Key Vault + secret management
 │   │   └─ monitoring/      Log Analytics Workspace
 │   ├─ envs/
 │   │   ├─ dev/             Dev environment root
 │   │   └─ stage/           Stage environment root
 │   └─ backend/             One-time state storage bootstrap
 ├─ .azure-pipelines/
 │   ├─ azure-pipelines.yml  Plan on PR, Apply on main
 │   └─ drift-detection.yml  Scheduled daily drift check
 ├─ .gitignore
 ├─ README.md
 ├─ commands.txt
 └─ goals.txt
```

---

## State Design

| Environment | State Key               | Storage Account |
|-------------|-------------------------|-----------------|
| dev         | dev/terraform.tfstate   | stgtfstate2606  |
| stage       | stage/terraform.tfstate | stgtfstate2606  |

Both state files live in the `tfstate` container inside `rg-tfstate`. Each environment is fully isolated — a plan in dev never sees stage resources.

---

## Environment Differences

| Feature                | Dev         | Stage       |
|------------------------|-------------|-------------|
| VNet CIDR              | 10.0.0.0/16 | 10.1.0.0/16 |
| Subnets                | 2           | 3 (+ mgmt)  |
| Storage replication    | LRS         | GRS         |
| Blob soft delete       | 7 days      | 30 days     |
| KV purge protection    | Off         | On          |
| Log Analytics          | ❌           | ✅           |
| NSG — allow HTTP       | ✅           | ❌ (HTTPS only) |
| Deny-all inbound rule  | ❌           | ✅           |

---

## Pipeline Flow

```
Push branch → open PR
      ↓
terraform plan runs automatically (PR comment)
      ↓
PR reviewed and merged to main
      ↓
terraform apply — dev (auto)
      ↓
terraform plan — stage
      ↓
Manual approval gate
      ↓
terraform apply — stage
```

---

## Security Decisions

**OIDC — Why no secrets?**
Azure DevOps exchanges a short-lived federated token with Azure AD at runtime. No client secrets are created, stored, or rotated. This is the zero-secret authentication model.

**Key Vault**
All sensitive values go into Key Vault. Outputs marked `sensitive = true` never appear in pipeline logs. `purge_protection = true` in stage prevents even soft-deleted vaults from being permanently removed for 90 days.

**`prevent_destroy`**
The Storage Account and Key Vault in all environments have `prevent_destroy = true`. A `terraform destroy` will error before touching them. You must remove the lifecycle block and re-plan before destruction is possible.

**Drift Detection**
A scheduled pipeline runs `terraform plan -detailed-exitcode` every day at 6 AM. Exit code 2 means the real infrastructure no longer matches the state — someone made a manual change. The pipeline fails loudly and the team is notified.

---

## How to Use

### First time only — bootstrap the backend
```bash
cd terraform/backend
terraform init
terraform apply
```

### Deploy Dev
```bash
cd terraform/envs/dev
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

### Deploy Stage
```bash
cd terraform/envs/stage
terraform init
terraform plan -out=stage.tfplan
terraform apply stage.tfplan
```

### Check for drift manually
```bash
terraform plan -detailed-exitcode
# Exit 0 = clean | Exit 2 = drift detected
```