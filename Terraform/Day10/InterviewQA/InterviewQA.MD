# Day 10 — Production-Grade Azure Infrastructure (azure-secure-foundation-iac)

> Production-grade Azure Infrastructure · Terraform · OIDC · Azure DevOps · Multi-environment

---

## Why This Day Exists

Days 1 through 9 taught you Terraform features in isolation. Day 10 is different.

Day 10 is the day you stop learning individual features and start building something a real company would trust in production. Everything from the previous days — remote state, modules, OIDC, Key Vault, lifecycle rules, CI/CD, drift detection — gets assembled into one coherent, professional project.

This is your portfolio anchor. When you apply for cloud or DevOps roles, this is what you show instead of listing "Terraform" on a CV. The difference between a candidate who says "I learned Terraform" and one who says "I built a production-grade multi-environment IaC project with OIDC-secured CI/CD, Key Vault integration, lifecycle protection, and automated drift detection" is significant. You are building the second person.

---

## What You Built

```
┌──────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                            │
│                                                                      │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐   │
│  │     DEV ENVIRONMENT         │  │    STAGE ENVIRONMENT         │   │
│  │  rg-demo-test-dev           │  │  rg-demo-test-stage          │   │
│  │                             │  │                              │   │
│  │  VNet 10.0.0.0/16           │  │  VNet 10.1.0.0/16            │   │
│  │  ├─ snet-app-dev            │  │  ├─ snet-app-stage           │   │
│  │  └─ snet-data-dev           │  │  ├─ snet-data-stage          │   │
│  │                             │  │  └─ snet-mgmt-stage          │   │
│  │  Storage (LRS)              │  │  Storage (GRS)               │   │
│  │  Key Vault                  │  │  Key Vault + purge protect    │   │
│  │  NSG (HTTP allowed)         │  │  NSG (HTTPS only, deny-all)  │   │
│  │                             │  │  Log Analytics Workspace     │   │
│  └─────────────────────────────┘  └─────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  rg-tfstate                                                   │   │
│  │  stgtfstate2606 → tfstate container                           │   │
│  │  ├─ dev/terraform.tfstate                                     │   │
│  │  └─ stage/terraform.tfstate                                   │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
azure-secure-foundation-iac/
├─ terraform/
│   ├─ modules/
│   │   ├─ networking/           VNet + Subnets + NSGs (dynamic rules)
│   │   ├─ storage/              Storage Account + lifecycle policy
│   │   ├─ keyvault/             Key Vault + secret management
│   │   └─ monitoring/           Log Analytics Workspace
│   ├─ envs/
│   │   ├─ dev/                  Dev: main.tf, backend.tf, variables.tf, outputs.tf, tfvars
│   │   └─ stage/                Stage: same structure, different values
│   └─ backend/                  One-time bootstrap: creates rg-tfstate + stgtfstate2606
├─ .azure-pipelines/
│   ├─ azure-pipelines.yml       Plan on PR, Apply on main, Approval gate on stage
│   └─ drift-detection.yml       Scheduled daily drift detection
├─ .gitignore
├─ README.md
├─ commands.txt
└─ goals.txt
```

---

## Remote Backend — Why It Exists and Why It Matters

Before writing a single resource, you bootstrapped a Storage Account to hold Terraform state. This is not optional in any real team environment.

Local state — the default `terraform.tfstate` file on your machine — is dangerous for three reasons. First, if your laptop is lost, corrupted, or reformatted, your state is gone and Terraform no longer knows what it manages in Azure. Second, if two people run Terraform simultaneously against the same environment, they corrupt each other's state. Third, a CI/CD pipeline agent is a temporary virtual machine — it is destroyed after every run. Any local state written there disappears immediately.

Remote state in Azure Blob solves all three. The state file lives in `stgtfstate2606`, container `tfstate`. Every environment gets its own key — `dev/terraform.tfstate` and `stage/terraform.tfstate`. They are isolated. A plan in dev never reads or affects stage state.

**The one-time bootstrap commands:**
```bash
az group create --name rg-tfstate --location "Central India"
az storage account create --name stgtfstate2606 --resource-group rg-tfstate --location "Central India" --sku Standard_LRS
az storage container create --name tfstate --account-name stgtfstate2606
```

You run these once. Every environment's `backend.tf` then points here. The storage account outlives every environment — when you destroy dev or stage, the state files remain safe.

---

## State Design

| Environment | State Key | Storage Account |
|---|---|---|
| dev | dev/terraform.tfstate | stgtfstate2606 |
| stage | stage/terraform.tfstate | stgtfstate2606 |

Both live in the same storage account but in separate keys. This means one team can destroy dev without touching stage. One pipeline can plan stage without locking dev. State isolation is the foundation of safe multi-environment infrastructure.

---

## Environment Differences — Why They Are Not the Same

| Feature | Dev | Stage |
|---|---|---|
| VNet CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| Subnets | 2 | 3 (+ mgmt) |
| Storage replication | LRS | GRS |
| Blob soft delete | 7 days | 30 days |
| KV purge protection | Off | On |
| Log Analytics | No | Yes |
| NSG — allow HTTP | Yes | No (HTTPS only) |
| Deny-all inbound | No | Yes |

Dev is cheaper and more permissive. You need fast iteration, easy access, lower cost. You do not need geo-redundant storage for test data. You do not need 90-day log retention for development activity.

Stage mirrors production constraints. GRS replication because stage validates production behaviour. Purge protection on Key Vault because once you enable it in prod it cannot be disabled — test that behaviour in stage first. HTTPS-only and deny-all rules because stage must catch security misconfigurations before they reach production. Log Analytics in stage because you need to observe behaviour under realistic conditions before relying on it in prod.

This is the discipline that separates engineers who understand environments from those who just copy files.

---

## Step-by-Step — What You Did and Why

---

### Step 0 — Folder Structure Design

**Why this step exists:**
The folder structure is an architectural decision, not a housekeeping task. `envs/dev` and `envs/stage` are separate Terraform root modules. Each has its own `backend.tf`, its own `terraform.tfstate` in Azure, and its own `terraform init` context. Running `terraform plan` in `envs/dev` is completely isolated from `envs/stage`. They share module code but share nothing at runtime.

`modules/` contains the reusable logic. `networking`, `storage`, `keyvault`, `monitoring` are each a self-contained module with inputs and outputs. Dev and stage both call these same modules but pass different variable values. One change to `modules/networking/main.tf` propagates to every environment on the next apply. Without modules, you have three copies of the same networking code — and when you fix a bug, you fix it in one place and forget the other two.

`backend/` is a special case. It is a one-time Terraform root that creates the storage account used by all other environments. It uses local state because it has nothing to point to remotely yet. After it runs once, it is never touched again unless you need to change the backend infrastructure itself.

---

### Step 1 — One-Time Backend Bootstrap

**Why this step exists:**
You cannot configure a remote backend that does not exist yet. The chicken-and-egg problem of remote state is: to use remote state you need the storage account, but to create the storage account with Terraform you need somewhere to put the state. The solution is to create the storage account manually — either via `az cli` or via a small dedicated Terraform configuration with local state — and never touch it again.

`terraform/backend/` is that small dedicated configuration. It runs once, creates `rg-tfstate` and `stgtfstate2606`, and stores its own state locally. After this, every environment points its backend config to `stgtfstate2606` and the bootstrap is done.

**What to remember:**
The backend storage account must be created before any environment can run `terraform init`. In a team setting, one senior engineer runs this once when the project is first set up. It is not part of the regular deployment pipeline — it is infrastructure for your infrastructure.

---

### Step 2 — OIDC Setup

**Why this step exists:**
Traditional CI/CD pipelines store a service principal client secret as a pipeline variable. That secret has an expiry date. Someone has to rotate it. If it leaks — from a pipeline log, a git commit, a disgruntled employee — an attacker has persistent access to your Azure subscription until the secret is revoked.

OIDC eliminates the secret entirely. Instead of a password, Azure DevOps exchanges a short-lived federated identity token with Azure AD at pipeline runtime. The token is valid for minutes, not months. There is nothing to store, nothing to rotate, nothing to leak.

The federated credential you create links a specific Azure DevOps organization, project, and service connection to a specific App Registration in Azure AD. Only that exact pipeline, in that exact project, can exchange tokens. A compromised pipeline in a different organization cannot impersonate it.

This is the modern, correct way to authenticate infrastructure pipelines. It is the pattern Finnish and EU companies increasingly require, both for security and for compliance with zero-standing-privilege principles.

---

### Step 3 — Networking Module with Dynamic Rules

**Why this step exists:**
NSG rules are the most frequently changed network configuration in any Azure environment. New application requirements, security reviews, compliance changes — all of them result in NSG rule updates. If you hardcode each rule as a separate `security_rule` block in your Terraform code, every new rule is a code change, a PR, a review, a merge. And every environment has a slightly different list hardcoded in different places.

Dynamic blocks with `for_each` solve this. Rules are defined as a variable — a list of maps. The dynamic block iterates that list and generates the rule resources. To add a rule you add one line to the variable definition. To remove a rule you remove one line. The logic stays in one place. Dev gets a different rules list than stage, but both use the same module code.

This is also where you learn why `for_each` is preferred over `count` for resource collections. With `count`, resources are indexed by number. If you remove rule index 2 from a list of 5, Terraform wants to destroy indices 2, 3, 4 and recreate 3 and 4 with shifted indices. With `for_each` keyed by rule name, removing one rule destroys only that rule. Everything else is untouched.

---

### Step 4 — Key Vault Integration

**Why this step exists:**
Secrets in Terraform code is how data breaches happen. A developer hardcodes a database password in `terraform.tfvars`, commits it, pushes to a public repository. It is scraped by automated tools within minutes. This happens constantly in the real world.

Key Vault is the Azure-native solution. Secrets are stored in the vault, not in code. Terraform reads them at apply time using a `data` source. They are never written to state in plain text when outputs are marked `sensitive = true`. They never appear in pipeline logs.

`purge_protection = true` in stage means that even if someone deletes the Key Vault, it cannot be permanently destroyed for 90 days. This gives you a recovery window. The reason to test this in stage and not just in prod is that once purge protection is enabled on a vault, it cannot be disabled. If you enable it without understanding the implication — that you cannot destroy and recreate a vault with the same name for 90 days — you will hit this on day one of trying to clean up your learning environment. Testing in stage first means you understand the behaviour before it costs you.

---

### Step 5 — Lifecycle Rules — `prevent_destroy`

**Why this step exists:**
`terraform destroy` is a command that deletes everything. In a shared team environment, on a bad day, someone runs it against the wrong environment. Or a pipeline misconfiguration targets prod instead of dev. Without protection, your storage account with years of data and your Key Vault with all your production secrets are gone in seconds.

`prevent_destroy = true` in the lifecycle block makes Terraform refuse to destroy that resource. The apply exits with an error before touching it. You must explicitly remove the lifecycle block, commit that change, and re-plan before destruction is possible. That deliberate friction is the point. It turns an accidental destroy into a multi-step intentional process with a git history trail.

In this project the Storage Account and Key Vault have `prevent_destroy = true`. The VNet and NSGs do not — they are stateless and recreatable without data loss.

**What to remember:**
`prevent_destroy` only works when Terraform manages the resource. If someone deletes the resource directly in the Azure Portal, Terraform cannot stop them. It will only catch it on the next plan when it detects drift.

---

### Step 6 — CI/CD Pipeline — Plan on PR, Apply on Main

**Why this step exists:**
Manual `terraform apply` from a developer's laptop is how production gets broken. No review. No audit trail. No gate. Someone runs it with untested changes at 4pm on a Friday and goes home.

The pipeline enforces a gate pattern. Every code change goes through a PR. The PR triggers `terraform plan` automatically. The plan output appears as a comment on the PR — reviewers see exactly what Terraform intends to create, modify, or destroy before they approve. Only after the PR is merged to main does `terraform apply` run.

Stage adds a second gate: manual approval. Even after plan succeeds and the PR is merged, a human must explicitly approve the stage deployment in Azure DevOps before apply runs. This means no stage change goes live without deliberate sign-off.

**The pipeline flow:**
```
Push branch → open PR
      ↓
terraform plan runs automatically
      ↓
PR reviewed → merged to main
      ↓
terraform apply — dev (automatic)
      ↓
terraform plan — stage
      ↓
Manual approval gate in Azure DevOps
      ↓
terraform apply — stage
```

The approval gate in Azure DevOps is configured on the `Environment` resource. Stage apply is a `deployment` job targeting the stage environment. The environment has a required approver. The pipeline pauses and waits. Nothing deploys until a human clicks approve.

---

### Step 7 — Drift Detection

**Why this step exists:**
In every real company, someone makes a manual change in the Azure Portal and calls it a "quick fix." They change an NSG rule, increase a storage account tier, add an access policy — directly in the portal, bypassing Terraform entirely. This is called drift. Your Terraform state now describes infrastructure that no longer exists in reality. The next apply may overwrite or undo the manual change silently, or create a conflict that breaks the deploy.

The drift detection pipeline runs `terraform plan -detailed-exitcode` on a schedule — every day at 6 AM. Exit code 0 means no changes — infrastructure matches state. Exit code 2 means changes were detected — drift exists. The pipeline fails loudly and the team is notified.

This does not automatically fix the drift. That is intentional. A human must investigate: was the manual change intentional and should it be codified in Terraform? Or was it an unauthorized modification that should be reverted? The pipeline surfaces the question. The team answers it.

**Exit codes you must know:**
- `0` — No changes. Infrastructure matches state exactly.
- `1` — Terraform error. Something is wrong with the configuration.
- `2` — Changes detected. State diverges from reality. Drift.

---

## Security Decisions

**OIDC — Zero secrets in the pipeline:**
Azure DevOps exchanges a short-lived federated token at runtime. No client secret is created, stored, or rotated. Even if an attacker gains full access to your pipeline configuration, there is no secret to extract. This is the zero-standing-privilege authentication model.

**`sensitive = true` on outputs:**
Outputs marked sensitive are redacted in `terraform output` and never appear in pipeline logs. Without this, a Key Vault URI or storage account connection string printed in plain text to a pipeline log is a credential exposure waiting to happen.

**`purge_protection = true` in stage:**
A deleted Key Vault in soft-delete state can be recovered. A purge-protected vault cannot be permanently deleted for 90 days even by an administrator. This is your last line of defence against accidental or malicious permanent data loss.

**`prevent_destroy` on critical resources:**
Adds mandatory friction to destructive operations. The git history of removing a lifecycle block and the pipeline approval required to apply that change creates an audit trail for every intentional destruction.

---

## Pipeline Architecture

```
.azure-pipelines/
├─ azure-pipelines.yml      → triggered on PR and main branch push
└─ drift-detection.yml      → scheduled trigger, runs daily at 6 AM
```

`azure-pipelines.yml` — handles normal deployment flow. PR triggers plan only. Merge to main triggers apply for dev automatically, then plan for stage followed by manual approval gate before apply.

`drift-detection.yml` — runs independently on a cron schedule. Executes `terraform plan -detailed-exitcode` against each environment. Any exit code 2 fails the pipeline and alerts the team. No apply ever runs from this pipeline — it is read-only by design.

---

## How to Use

**First time only — bootstrap the backend:**
```bash
cd terraform/backend && terraform init && terraform apply
```

**Deploy Dev:**
```bash
cd terraform/envs/dev && terraform init && terraform plan -out=dev.tfplan && terraform apply dev.tfplan
```

**Deploy Stage:**
```bash
cd terraform/envs/stage && terraform init && terraform plan -out=stage.tfplan && terraform apply stage.tfplan
```

**Check for drift manually:**
```bash
terraform plan -detailed-exitcode
```

**Verify state files exist in Azure:**
```bash
az storage blob list --account-name stgtfstate2606 --container-name tfstate --output table
```

---

## Concepts You Can Now Answer

**Why remote state over local state:**
Local state is lost if the machine is lost, corrupted if two people apply simultaneously, and incompatible with CI/CD pipelines that use temporary agents. Remote state in Azure Blob is persistent, lockable, and accessible from any machine or pipeline agent.

**Why modules over copy-paste:**
A bug fixed in a module is fixed everywhere that module is used. Copy-pasted code requires the same fix in every copy — and in practice, one copy gets missed. Modules enforce a single source of truth for infrastructure logic.

**Why OIDC over client secrets:**
Secrets have expiry dates, need rotation, and can be leaked. OIDC tokens are generated at runtime, valid for minutes, and cannot be stored or reused. There is nothing to steal.

**Why `prevent_destroy` exists:**
It converts an accidental two-second mistake into a deliberate multi-step process with a git history trail. The friction is the feature.

**Why drift detection matters:**
Manual portal changes are invisible to Terraform. Without drift detection, you can operate for weeks with infrastructure that no longer matches your code, accumulating silent divergence until it causes an incident. Scheduled detection surfaces the divergence immediately.

**Why dev and stage are different:**
Dev optimises for speed and cost. Stage validates production behaviour. The differences in replication, retention, purge protection, and security rules exist because each environment has different risk profiles and different purposes.

---

## Where You Are After Day 10

You are approximately 60-65% of a junior cloud infrastructure engineer.

Skills confirmed through this project: Terraform core, remote state management, module design, dynamic and conditional logic, lifecycle management, CI/CD pipeline with Azure DevOps, OIDC authentication, Key Vault integration, drift detection.

Your next arc to become competitive for Finnish and EU cloud roles covers Azure networking deep dive — VNet peering, private endpoints, DNS — AKS with Terraform, Azure Monitor and alerting, cost management, Azure Policy, Terratest basics, and multi-region design.

Day 10 is the day you stop being someone who learned Terraform and start being someone who can be trusted with infrastructure.