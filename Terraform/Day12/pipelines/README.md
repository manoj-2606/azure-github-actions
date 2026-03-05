# Pipelines — Day 12 Secure Network Architecture

## Structure
```
pipelines/
├── azure-pipelines.yml        ← Main pipeline: 3 stages
└── templates/
    ├── terraform-plan.yml     ← Reusable: install + init + validate + plan
    ├── terraform-apply.yml    ← Reusable: install + init + apply
    └── terraform-destroy.yml  ← Reusable: install + init + destroy
```

---

## Pipeline Stages
```
Push to main
     │
     ▼
┌─────────┐     ┌─────────┐     ┌──────────┐
│  Plan   │────▶│  Apply  │     │ Destroy  │
│ (auto)  │     │ (auto)  │     │ (manual) │
└─────────┘     └─────────┘     └──────────┘
```

| Stage | Trigger | What it does |
|---|---|---|
| Plan | Every push + every PR | init → validate → plan → publish artifact |
| Apply | Push to main only | download plan → init → apply |
| Destroy | Manual only (BUILD_DESTROY=true) | init → destroy |

---

## Prerequisites in Azure DevOps

### Variable Group: `Terraform-day12-vars`
Go to **Pipelines → Library → + Variable Group**

| Variable | Value |
|---|---|
| ARM_CLIENT_ID | Your Service Principal client ID |
| ARM_TENANT_ID | Your Azure AD tenant ID |
| ARM_SUBSCRIPTION_ID | Your subscription ID |
| BACKEND_RESOURCE_GROUP | rg-day11-tfstate |
| BACKEND_STORAGE_ACCOUNT | stday11tfstate7771 |
| BACKEND_CONTAINER | tfstate |

### Service Connection: `azure-service-connection`
**Project Settings → Service connections → Azure Resource Manager
→ Workload Identity Federation (OIDC)**

### Environments
**Pipelines → Environments → New environment**
- `day12-dev` → used by Apply stage
- `day12-destroy` → used by Destroy stage

---

## How OIDC Authentication Works
```
Pipeline starts
     │
     ▼
AzureCLI@2 task (addSpnToEnvironment: true)
     │  fetches OIDC token from service connection
     ▼
ARM_OIDC_TOKEN set as pipeline variable
     │
     ▼
Terraform init/plan/apply
     │  uses ARM_USE_OIDC=true + ARM_OIDC_TOKEN
     ▼
Azure authenticates via federated credential
     │  no client secret stored anywhere
     ▼
Resources created in Azure
```

---

## How to Trigger Destroy

1. Go to **Pipelines → day12-secure-network → Run pipeline**
2. Click **Variables**
3. Add variable: `BUILD_DESTROY` = `true`
4. Click **Run**

> Destroy will never run on a normal push — only when
> BUILD_DESTROY=true is explicitly passed.