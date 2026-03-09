# Day 13 — Platform Monitoring & Observability

> Infrastructure without monitoring is not infrastructure. It is hope.

---

## Why This Day Exists

You spent 12 days building infrastructure. Resource groups, Key Vaults, Storage Accounts, VNets, NSGs, pipelines. All of it runs. None of it is visible.

If someone deletes a secret from your Key Vault at 3am — you will not know.
If your NSG silently drops production traffic — you will not know.
If a service principal makes a destructive change — you will not know.

Day 13 fixes that. You are adding eyes to everything you built.

This is also not optional in Europe. GDPR Article 32 requires technical measures to ensure data security. NIS2 requires monitoring of critical systems. ISO 27001 requires audit logging. Finnish and EU companies that interview you will ask how you handle observability and compliance. This is your answer — built, not memorized.

---

## What You Built

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                           │
│                                                                     │
│   ┌─────────────┐   ┌──────────────┐   ┌───────┐   ┌──────────┐   │
│   │  Key Vault  │   │   Storage    │   │  VNet │   │   NSG    │   │
│   │             │   │   Account    │   │       │   │          │   │
│   └──────┬──────┘   └──────┬───────┘   └───┬───┘   └────┬─────┘   │
│          │                 │               │             │         │
│          └────────────┬────┘               └──────┬──────┘         │
│                       │  Diagnostic Settings       │                │
│          Activity Logs│                            │                │
│          (Subscription)◄───────────────────────────┘               │
│                       │                                             │
│                       ▼                                             │
│          ┌────────────────────────┐                                 │
│          │   Log Analytics        │                                 │
│          │   Workspace            │◄── KQL Queries                  │
│          └────────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Remote Backend — Why You Needed the Storage Account

Before the first line of Terraform, you created a Storage Account (`sttfstateday13`) and a container (`tfstate`). You may not have noticed it being used — but it was.

When your Azure DevOps pipeline runs `terraform init`, it connects to that storage account and writes your state file there as `day13.terraform.tfstate`. Without this, state would only exist on the pipeline agent — a temporary virtual machine that gets destroyed after every run. Your next pipeline run would try to recreate every single resource from scratch, causing conflicts and failures.

**Verify it yourself:**
Azure Portal → Storage Accounts → `sttfstateday13` → Containers → tfstate → you will see `day13.terraform.tfstate` sitting there.

This is why remote backend is not optional in team environments. It is the single source of truth for what Terraform believes exists in Azure.

**The az commands that created it:**
```bash
az group create --name rg-tfstate-day13 --location centralindia
az storage account create --name sttfstateday13 --resource-group rg-tfstate-day13 --location centralindia --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2
az storage container create --name tfstate --account-name sttfstateday13
```

---

## Folder Structure

```
Day13/
├── azure-pipelines.yml                 # Azure DevOps pipeline — main entry point
├── providers.tf                        # AzureRM provider + remote backend config
├── main.tf                             # Root: creates all resources, calls module
├── variables.tf                        # Input variable declarations
├── outputs.tf                          # Exposed values after apply
├── terraform.tfvars                    # Your actual values — never commit this
├── .gitignore                          # Excludes state, tfvars, .terraform/
│
├── pipelines/
│   ├── templates/
│   │   ├── tf-init.yml                 # Reusable: terraform init step
│   │   ├── tf-plan.yml                 # Reusable: fmt check + validate + plan
│   │   └── tf-apply.yml                # Reusable: terraform apply step
│   └── vars/
│       └── centralindia.yml            # Pipeline variables: region, backend, SA name
│
└── modules/
    └── monitoring/
        ├── main.tf                     # Log Analytics Workspace resource
        ├── variables.tf                # Module input variables
        ├── outputs.tf                  # workspace_id, workspace_name
        ├── diagnostic_keyvault.tf      # Diagnostic setting → Key Vault
        ├── diagnostic_storage.tf       # Diagnostic setting → Storage Account + Blob
        ├── diagnostic_network.tf       # Diagnostic setting → NSG + VNet
        └── activity_logs.tf            # Subscription-level activity logs
```

---

## Step-by-Step — What You Did and Why

---

### Step 1 — Project Structure + Providers

**Why this step exists:**
Terraform needs to know what provider to use, what version to lock it to, and where to store state before it can do anything. The folder structure you define here determines how clean your module boundaries are for the rest of the project.

`providers.tf` locks the AzureRM provider to `~> 3.100`. Without version locking, `terraform init` can silently pull a breaking version and your apply fails with no obvious cause.

`terraform.tfvars` holds your actual values — subscription ID, location, prefix. This file never goes into git. Anyone with this file and your service principal can deploy into your subscription.

**What to remember:**
The `purge_soft_delete_on_destroy = true` feature flag in the provider exists because Key Vault soft delete is enabled by default. When you run `terraform destroy` daily for learning, without this flag the vault enters a soft-deleted state and blocks you from recreating it with the same name the next day. This flag purges it completely on destroy.

---

### Step 2 — Remote Backend + Pipeline YAML + Log Analytics Workspace Module

**Why this step exists:**
Three things connect here.

The backend block in `providers.tf` points Terraform at the storage account you created manually. From this point forward, state is stored in Azure — not on your machine, not on the pipeline agent. This is mandatory for any pipeline-based workflow.

The Azure DevOps YAML pipeline has three stages — Init, Plan, Apply — and this design is deliberate. The Apply stage has a condition:

```yaml
condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

**Why that condition exists:** Without it, every pull request from every developer would trigger a real `terraform apply` against live infrastructure. A junior engineer opens a PR from a feature branch — production resources get created, modified, or destroyed before anyone reviews the code. The condition gates Apply to the `main` branch only. PRs trigger Plan only — which is safe and read-only. The reviewer sees exactly what Terraform intends to do, approves, merges to main, and only then does Apply run. Plan is your preview. Apply is your commitment.

The `tf-plan.yml` template includes `terraform fmt -recursive -check`. The `-check` flag means it fails the pipeline if any file is not formatted correctly. It does not auto-fix. The engineer fixes it locally. This is intentional — the pipeline enforces discipline, it does not substitute for it.

The Log Analytics Workspace uses `PerGB2018` SKU with 30-day retention. This is the current standard SKU. `retention_in_days = 30` is the minimum for most compliance requirements — increase to 90 or 365 in production depending on your regulatory obligations.

---

### Step 3 — Root main.tf: All Resources + Module Wiring

**Why this step exists:**
The root `main.tf` is the orchestrator. It creates the resources that will be monitored — Key Vault, Storage Account, VNet, NSG — and then passes their resource IDs into the monitoring module.

This reveals how Terraform's dependency graph works. The diagnostic setting needs the Key Vault ID to exist before it can be created. By writing:

```hcl
key_vault_id = azurerm_key_vault.main.id
```

You are creating a dependency edge. Terraform reads this and builds an execution order: create Key Vault first, then pass its ID to the module, then create the diagnostic setting. If Key Vault creation fails, Terraform halts that entire branch. The diagnostic setting never gets attempted. This is not Terraform being smart — it is the reference itself that creates the ordering.

**Key Vault needs `tenant_id` — Storage Account and VNet do not. Why:**
Key Vault is identity-aware. It integrates directly with Azure Active Directory to verify who can access secrets. The `tenant_id` tells Key Vault which Azure AD tenant to trust for authentication. If a caller presents a token, Key Vault checks it against this tenant. If the tenant_id is wrong, no identity can ever be validated — access policies become unreachable and every operation returns 401. Storage Account and VNet have no such AAD identity verification baked into the resource definition itself. Their access control is handled through RBAC and network rules separately.

`data "azurerm_client_config" "current" {}` fetches the tenant ID dynamically from whoever is running Terraform — your service principal in the pipeline, your user locally. You never hardcode a tenant ID. If you hardcode it and that ID ever changes, Key Vault becomes inaccessible with no obvious error.

---

### Step 4 — Diagnostic Settings: Key Vault

**Why this step exists:**
A diagnostic setting is a separate Terraform resource — not a property of the Key Vault block. Azure treats it as an independent entity that points at a target resource. This has one important consequence: if you delete the Log Analytics Workspace, the diagnostic setting still exists in Azure but silently has nowhere to send data. No error. No warning. Just silence. Your audit trail disappears without any indication.

`AuditEvent` is the category that matters most for Key Vault. Every secret read, every key operation, every access policy change is recorded here. This is your GDPR audit trail. Without it you cannot answer: "Who accessed the database password on March 3rd at 2am?" With it you can answer that question in under 30 seconds using a KQL query.

**Real-world lesson hit during this step:**
Subscription Owner does not grant Key Vault data plane access. Owner gives you control plane access — create, delete, configure the vault. It gives you zero ability to read or write secrets. Key Vault has a separate access policy layer that must be explicitly configured. This is by design. Even a global admin can be locked out of secrets without a deliberate access policy grant.

The fix in Terraform is to add this to the Key Vault resource block:

```hcl
access_policy {
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "List", "Delete", "Purge"]
}
```

Without this, every fresh deploy creates a vault that is locked to everyone including the deployer.

---

### Step 5 — Diagnostic Settings: Storage Account

**Why this step exists:**
Storage Account diagnostics are architecturally different from Key Vault. A Storage Account is a parent resource with child sub-resources — Blob, Queue, Table, File — each requiring its own diagnostic setting. The parent-level setting captures metrics. The blob-level setting captures data operations.

`StorageRead`, `StorageWrite`, `StorageDelete` are the three categories that matter for security:
- `StorageDelete` — tells you if data was wiped
- `StorageRead` — tells you if data was exfiltrated
- `StorageWrite` — tells you if data was tampered with

These three log lines are the difference between "we had an incident" and "we can prove exactly what was taken and when."

**Important lesson from this step:**
The blob diagnostic setting uses string interpolation to construct the target resource ID:

```hcl
target_resource_id = "${var.storage_account_id}/blobServices/default"
```

This is outside Terraform's safety net. Terraform sees a plain string — it cannot validate it during plan. `terraform plan` succeeds. `terraform apply` succeeds. If the path is wrong, Azure silently fails to attach the setting and logs never arrive. You will not find out until you query Log Analytics and get zero results. Always use `az monitor diagnostic-settings categories list --resource "<resource-id>"` to verify supported categories before writing diagnostic settings.

---

### Step 6 — Diagnostic Settings: NSG + VNet

**Why this step exists:**
Network diagnostics give you visibility into traffic behavior. NSG logs tell you which traffic was allowed and which was denied — this is how you detect port scanning, brute force attempts, and lateral movement.

Two log categories for NSG:
- `NetworkSecurityGroupEvent` — records individual flow evaluations and rule matches. Tells you source IP, destination port, which rule matched.
- `NetworkSecurityGroupRuleCounter` — records how many times traffic hit each rule per time window.

**Why both matter together:**
`RuleCounter` detects attacks through volume anomaly. A deny rule going from 3 hits per minute to 400 hits per minute in 60 seconds is a port scan. `NetworkSecurityGroupEvent` then tells you the exact source IP and which ports were targeted. One detects. The other investigates. With only one you are either blind to the pattern or blind to the detail.

**Real limitation discovered:**
NSG does not support `AllMetrics`. Azure returns 400 Bad Request if you try. This is not documented clearly in Terraform docs. Every Azure resource type has its own supported diagnostic categories. Always verify with:

```bash
az monitor diagnostic-settings categories list --resource "<resource-id>" -o table
```

Before writing any diagnostic setting for a resource type you have not used before.

---

### Step 7 — Subscription Activity Logs

**Why this step exists:**
Everything in Steps 4-6 captures what happens inside resources — data plane operations. Activity logs capture what happens to resources — control plane operations.

Someone deletes your Key Vault, modifies a firewall rule, assigns a new RBAC role, changes a policy — none of that appears in diagnostic logs. All of it appears in activity logs.

The mechanism is different. You are not attaching a diagnostic setting to a specific resource. You are pointing it at the entire subscription:

```hcl
target_resource_id = "/subscriptions/${var.subscription_id}"
```

One setting covers every resource mutation in the subscription. This is the log that answers: "Who ran terraform destroy on the wrong workspace at 3am?" With caller identity, IP address, timestamp, and exact operation recorded.

**Cost control for large enterprises:**
Activity logs at high volume generate significant Log Analytics ingestion costs. The architecture solution is dual-destination diagnostic settings — send logs to Log Analytics for 30 days of active querying at full price, and simultaneously to a Storage Account for 365+ days of compliance archival at blob storage pricing. One diagnostic setting, two destinations. You already have both resources in this project. In production you would add a second `storage_account_id` destination to the activity logs diagnostic setting.

---

## Validation — What Confirmed It Worked

After apply, two KQL queries confirmed the pipeline was functional:

**Diagnostic logs from Key Vault:**
```kql
AzureDiagnostics
| where ResourceType == "VAULTS"
| project TimeGenerated, OperationName, ResultType, CallerIPAddress
| take 10
```

This returned `SecretSet` and `VaultGet` operations with timestamps and caller IPs — every action against the vault recorded.

**Activity logs from subscription:**
```kql
AzureActivity
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup
| take 10
```

This returned `MICROSOFT.KEYVAULT/VAULTS/WRITE` entries showing Terraform's access policy modification — caller identity `manojmanojkumar2513@gmail.com`, timestamp, resource group. A compliance auditor could reconstruct every infrastructure change from this log alone.

---

## Errors Hit and Why They Matter

| Error | Cause | Fix | Lesson |
|---|---|---|---|
| `fmt -check` exit code 3 | Manual alignment of `=` signs in main.tf | `terraform fmt -recursive` locally | Run fmt before every commit, not after |
| NSG 400 Bad Request AllMetrics | NSG does not support metric export | Remove metric block from NSG diagnostic setting | Always verify supported categories with az cli before writing |
| Key Vault Forbidden 403 | Owner role does not grant data plane access | `az keyvault set-policy` with correct object-id | Add access_policy block to Terraform Key Vault resource |
| Wrong object-id in set-policy | `az account show --query id` returns subscription ID not user ID | Use `az ad signed-in-user show --query id` | Know the difference between subscription ID and principal object ID |

---

## Concepts You Can Now Answer

**Metrics vs Logs:**
Metrics are numerical time-series data — CPU percentage, request count, latency in milliseconds. They answer "how much" and "how fast." Logs are structured event records — who did what, when, what was the result. They answer "what happened." Both go to Log Analytics but serve different investigative purposes.

**What diagnostic settings actually do:**
They create a forwarding rule from a resource's internal telemetry to an external destination. Without a diagnostic setting, logs exist inside the resource but are discarded. The setting is the pipe.

**Why centralized monitoring:**
Cross-resource correlation, single compliance surface, unified security view. If each team has their own workspace, you cannot correlate a suspicious Key Vault access with an unusual storage read at the same timestamp from the same IP. Centralized means one query answers questions across your entire infrastructure.

**What logs detect security incidents:**
`AuditEvent` in Key Vault for unauthorized secret access. `AzureActivity` for destructive control plane changes. `NetworkSecurityGroupRuleCounter` for traffic volume anomalies indicating scanning. `StorageDelete` for data destruction. Combined, these four cover the most common incident patterns.

**Why activity logs matter:**
They are the only record of who changed your infrastructure and when. Without them, a misconfiguration or destructive change is unattributable. With them, every Terraform apply, every portal click, every CLI command that touches Azure is recorded with caller identity and timestamp.