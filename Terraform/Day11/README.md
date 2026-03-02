# Day 11 — Identity, RBAC & Zero-Trust Infrastructure

> **Production-grade identity and access management on Azure using Terraform, deployed via Azure DevOps with OIDC authentication.**

---

## Why This Project Exists

Most cloud engineers start by assigning `Contributor` at the subscription level to everything — pipelines, apps, service accounts — and call it done. It works. But it is not engineering. It is a security liability waiting to be exploited.

This project exists to break that habit.

Day 11 forces you to think like a security engineer, not just a DevOps engineer. Every identity has a reason. Every role has a scope. Every permission is the minimum needed and nothing more. This is how infrastructure is built in companies that take security seriously — banks, healthcare platforms, SaaS companies operating under ISO 27001, SOC 2, or PCI-DSS compliance.

---

## What This Project Builds

All resources are deployed to **Central India** inside `rg-day11-identity`.

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | `rg-day11-identity` | Container for all Day 11 resources |
| Resource Group | `rg-day11-tfstate` | Isolated backend state storage |
| Storage Account | `stday11tfstateXXXXX` | Terraform remote state backend |
| Storage Account | `stday11app001` | Application storage for RBAC exercise |
| User-Assigned Managed Identity | `id-day11-app` | Workload identity — no passwords |
| Key Vault | `kv-day11-001` | Secret store with RBAC authorization |
| Role Assignment | Storage Blob Data Contributor | Identity → Storage Account scope |
| Role Assignment | Reader | Identity → Resource Group scope |
| Role Assignment | Key Vault Secrets User | Identity → Key Vault scope |

---

## Project Structure

```
Day11/
├── main.tf                  # Root — wires all modules together
├── providers.tf             # Azure provider + remote backend config
├── variables.tf             # Input variable declarations
├── terraform.tfvars         # Actual variable values
├── outputs.tf               # Outputs after apply
├── modules/
│   ├── identity/            # Creates User-Assigned Managed Identity
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rbac/                # Creates role assignments via for_each
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── keyvault/            # Creates Key Vault with RBAC mode
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── pipeline/
    └── azure-pipelines.yml  # ADO pipeline — Validate → Plan → Apply
```

---

## Core Concepts Learned

### 1. Managed Identity — No More Secrets
A Managed Identity is an Azure Active Directory identity tied to a resource. It has no password, no client secret, and no expiry date. Azure handles the credential lifecycle automatically.

**User-Assigned** (what we built) lives independently of any single resource. You can attach it to multiple VMs, App Services, or Functions. If the resource is deleted, the identity survives.

**System-Assigned** is tied to one resource. When the resource dies, the identity dies. Less flexible, but simpler for single-resource scenarios.

### 2. RBAC as Code — Access Is Auditable
When role assignments live in Terraform, they are version-controlled. Every change goes through a pull request. Every apply is logged in ADO. If someone removes a role, Terraform detects it on the next plan and asks you to confirm the destroy.

This is the opposite of manual portal clicking — which leaves no audit trail and is impossible to review or roll back.

### 3. for_each Role Assignments — Scale Without Duplication
Instead of writing one `azurerm_role_assignment` block per role, we pass a map. One module handles 1 role or 20 roles identically. Adding a new role assignment in production means adding one entry to a map — not copy-pasting resource blocks.

### 4. Scoping Hierarchy — Least Privilege in Practice
```
Subscription          ← widest, almost never correct
  └── Resource Group  ← good default
        └── Resource  ← preferred for specific access
```

Every role assignment in this project is scoped to the **tightest level that still works**:
- Blob access → scoped to the storage account, not the RG
- Read access → scoped to the RG, not the subscription
- Secret access → scoped to the specific Key Vault

### 5. Key Vault RBAC Model — Modern vs Legacy
Azure Key Vault has two access models. Access Policies (legacy) store permissions inside the vault itself and cannot be audited by Azure Policy. RBAC model (modern) uses the same role assignment system as every other Azure resource — consistent, auditable, and manageable in the same Terraform module as everything else.

We used `enable_rbac_authorization = true` and assigned `Key Vault Secrets User` — read-only secret access, nothing more.

### 6. OIDC Pipeline Auth — No Stored Secrets
The pipeline authenticates to Azure using OpenID Connect. ADO generates a short-lived JWT token per pipeline run. Terraform exchanges this token for an Azure access token. There is no client secret stored anywhere — not in ADO, not in code, not in environment variables.

The key variables that make this work:
- `ARM_USE_OIDC=true` — tells the provider to use token exchange
- `ARM_OIDC_TOKEN=$idToken` — the JWT from ADO
- `ARM_CLIENT_ID` — which service principal to authenticate as
- `ARM_TENANT_ID` — which Azure AD tenant

---

## Pipeline Flow

```
Push to main branch
        │
        ▼
┌─────────────────┐
│  VALIDATE stage │  terraform fmt -check + terraform validate
└────────┬────────┘
         │ success
         ▼
┌─────────────────┐
│   PLAN stage    │  terraform plan → saves binary artifact
└────────┬────────┘
         │ success + branch = main
         ▼
┌─────────────────┐
│   APPLY stage   │  downloads binary → terraform apply
└─────────────────┘
```

The plan binary is saved as a pipeline artifact and downloaded by the Apply stage. This guarantees Apply runs the **exact same plan** that was reviewed — no re-planning, no surprises between stages.

---

## Least Privilege Audit

| Identity | Role | Scope | Reason |
|---|---|---|---|
| `id-day11-app` (Managed Identity) | Storage Blob Data Contributor | `stday11app001` only | Needs blob read/write, not full storage control |
| `id-day11-app` (Managed Identity) | Reader | `rg-day11-identity` only | Needs to see resources, not modify them |
| `id-day11-app` (Managed Identity) | Key Vault Secrets User | `kv-day11-001` only | Needs to read secrets, not manage the vault |
| Pipeline SP | Contributor | `rg-day11-identity` only | Needs to create/modify resources in this RG |
| Pipeline SP | User Access Administrator | `rg-day11-identity` only | Needs to write role assignments via Terraform |

**What nothing has:** Owner anywhere. Contributor at subscription. Any role at subscription scope.

---

## Real-World Application

This exact pattern is used in production by:

**Financial services** — Every microservice has its own managed identity. Role assignments are reviewed in pull requests. No human ever touches the portal to grant access.

**Healthcare platforms** — HIPAA compliance requires audit trails for all access changes. RBAC as code provides this automatically through git history and ADO deployment logs.

**SaaS companies** — Applications running on App Service or AKS authenticate to Key Vault and Storage using managed identities. No secrets in environment variables. No rotation schedules. No leaked credentials in git history.

**Regulated industries (EU)** — GDPR and industry regulations require demonstrable access controls. Terraform state + git history + ADO logs = demonstrable, auditable access control.

---

## What You Can Achieve After This Project

After completing Day 11 you can:

- Design an identity architecture from scratch without using passwords or secrets
- Write reusable Terraform modules that scale from 1 role assignment to 100
- Scope permissions correctly at every level of the Azure hierarchy
- Explain the difference between Managed Identity (who you are) and RBAC (what you can do)
- Configure Key Vault to use the modern RBAC model
- Build a three-stage CI/CD pipeline with OIDC authentication
- Conduct a least-privilege audit for any Azure environment
- Pass a security review for cloud infrastructure at an enterprise employer

---

## Prerequisites

- Azure subscription with Owner access (for initial SP role assignment)
- Azure DevOps organization with an OIDC service connection configured
- Azure CLI installed and logged in locally
- Terraform 1.5+ installed locally
- Git repository connected to Azure DevOps

---

## How to Deploy

**First time only — bootstrap the backend:**
```bash
az group create --name rg-day11-tfstate --location centralindia
az storage account create --name YOUR_UNIQUE_NAME --resource-group rg-day11-tfstate --location centralindia --sku Standard_LRS
az storage container create --name tfstate --account-name YOUR_UNIQUE_NAME --auth-mode login
az group create --name rg-day11-identity --location centralindia
```

**Grant pipeline SP permission to assign roles:**
```bash
az role assignment create \
  --assignee YOUR_SP_OBJECT_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUB_ID/resourceGroups/rg-day11-identity"
```

**Deploy via pipeline:**
```bash
git add Terraform/Day11/
git commit -m "Day 11 - Identity, RBAC and Zero Trust Infrastructure"
git push origin main
```

The pipeline triggers automatically on push to main.

---

## Author

Built as part of a structured 30-day Azure DevOps and Terraform learning programme focused on production-grade infrastructure engineering.