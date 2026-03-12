# Day 14 — Governance & Policy Enforcement

> Security rules that depend on humans following them are not rules. They are suggestions. Azure Policy makes non-compliance technically impossible.

---

## Why This Day Exists

You have built 13 days of secure infrastructure. Proper RBAC. Private endpoints. Monitoring. Zero public exposure. All of it can be undone in 30 seconds by a developer who does not know the rules or does not follow them.

Day 14 removes the human dependency entirely. Azure Policy enforces rules at the Azure Resource Manager API level — before any resource is created, regardless of the tool used. Terraform, az cli, the Azure Portal, a REST API call — every request passes through the same policy evaluation gate. Non-compliant requests are rejected before Azure touches anything.

This is what "platform engineering" means. You are not just deploying resources. You are building the guardrails that govern how every engineer in the organisation deploys resources. Governance-as-code — the same version control, review process, and pipeline discipline applied to the rules themselves.

---

## Target Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                            │
│                                                                      │
│  Policy Definitions (subscription-level, not inside any RG)         │
│  ├─ day14-allowed-locations     → Deny if region not approved        │
│  ├─ day14-require-tag-environment → Deny if tag missing              │
│  ├─ day14-require-tag-owner       → Deny if tag missing              │
│  ├─ day14-require-tag-costcenter  → Deny if tag missing              │
│  ├─ day14-deny-public-storage     → Deny if public access enabled    │
│  └─ day14-audit-diagnostic-settings → Audit if no diagnostics        │
│                    │                                                 │
│                    │ grouped into                                    │
│                    ▼                                                 │
│  Policy Initiative: day14-governance-baseline                        │
│                    │                                                 │
│                    │ assigned at scope                               │
│                    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  rg-governance-day14                                        │    │
│  │                                                             │    │
│  │  Every resource creation here is evaluated against          │    │
│  │  all 6 policies before Azure creates it.                    │    │
│  │                                                             │    │
│  │  Non-compliant → RequestDisallowedByPolicy                  │    │
│  │  Compliant → Resource created                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
Day14/
├── .gitignore
├── azure-pipelines.yml               # Main pipeline — Plan + Apply
├── commands.txt
├── goals.txt
├── purpose.txt
├── README.md
├── main.tf                           # Root: RG + module call
├── variables.tf                      # Input variable declarations
├── outputs.tf                        # Policy initiative ID, assignment ID
├── providers.tf                      # AzureRM provider + remote backend
├── terraform.tfvars                  # Local dev values — never committed
├── modules/
│   └── governance/
│       ├── main.tf                   # data azurerm_client_config only
│       ├── variables.tf              # Module inputs
│       ├── outputs.tf                # initiative_id, assignment_id
│       ├── policy_definitions.tf     # 6 custom policy definitions
│       ├── policy_initiative.tf      # Policy set bundling all definitions
│       └── policy_assignments.tf     # Assignment at RG scope
└── pipelines/
    ├── templates/
    │   ├── tf-init.yml               # Backend bootstrap + terraform init
    │   ├── tf-plan.yml               # fmt + validate + plan with -var flags
    │   └── tf-apply.yml              # apply from saved plan binary
    └── vars/
            centralindia.yml          # Pipeline variables
```

---

## Remote Backend — Why It Cannot Live Inside the Pipeline Naively

Before Terraform can run, the backend storage account must exist. When the pipeline executes `terraform init`, it immediately connects to the storage account. If the account does not exist yet, init fails before any resource is created.

Day 14 solves this with an **idempotent bootstrap stage** inside the pipeline itself. Every pipeline run attempts to create the storage account. If it already exists, `|| true` catches the non-zero exit code from the Azure CLI and allows the pipeline to continue. If it does not exist, it gets created.

```bash
az storage account create --name sttfstateday14 ... --output none || true
```

`|| true` is not sloppy error handling. It is intentional idempotency. The storage account either gets created or it already exists — either outcome is success for the pipeline's purpose.

**Why `terraform.tfvars` is never committed:**
It contains environment-specific values including subscription IDs. In a pipeline, variables are passed using `-var` flags directly in the plan command. This keeps secrets out of git history while still giving Terraform the values it needs.

---

## Step-by-Step — What You Did and Why

---

### Step 1 — Project Structure + Documentation + Providers

**Why this step exists:**
Governance is the most senior-level Terraform work you have done. Before writing a single resource block, you need to understand what you are building and why. The documentation files are not overhead — they are the reference that keeps you from writing policies that are too broad, too narrow, or wrong in scope.

`providers.tf` locks AzureRM to `~> 3.100`. This is critical for Day 14 because AzureRM 3.x removed `azurerm_policy_assignment` and replaced it with scope-specific resources. If you do not pin the version and a breaking change ships, your governance pipeline fails silently with a cryptic "resource type not found" error.

The backend block points to `sttfstateday14`. The backend is created by the pipeline bootstrap stage — not manually, not before you start. This is the Day 14 pattern: the pipeline is self-bootstrapping.

**Interview question you must be able to answer:**

Q: A pipeline is self-bootstrapping — it creates its own backend on first run. What is the risk of this pattern, and how does `|| true` address it?

A: The risk is that on the second run, `az storage account create` returns exit code 1 because the account already exists. Without `|| true`, the pipeline fails at the bootstrap stage before Terraform even starts — not because anything went wrong, but because the CLI treats "already exists" as an error. `|| true` catches any non-zero exit code and returns success, making the stage idempotent. The storage account either gets created or already exists — the pipeline continues either way.

---

### Step 2 — Pipeline YAML Files

**Why this step exists:**
The pipeline introduces a pattern not used in previous days — the bootstrap stage runs inside the Plan template, not as a separate stage. This means every pipeline run, whether triggered by a PR or a push to main, verifies the backend exists before attempting init. There is no separate manual step and no dependency on something existing before the pipeline runs.

The Apply stage is still gated to `main` branch only via the condition:
```yaml
condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

Variables are passed to terraform plan using `-var` flags instead of `terraform.tfvars`. The tfvars file is gitignored permanently — it exists only for local development. The pipeline gets values from the `-var` flags hardcoded in the template. In production, sensitive values would come from Azure DevOps Variable Groups.

**The service principal needs one extra role for Day 14:**
`Resource Policy Contributor` at subscription scope. The regular `Contributor` role does not include `Microsoft.Authorization/policyAssignments/write`. Without `Resource Policy Contributor`, the pipeline SP can create policy definitions but cannot assign them — resulting in a 403 on the assignment resource.

**Interview question you must be able to answer:**

Q: Your pipeline has Contributor on the resource group but policy assignment fails with 403. What role is missing and why is Contributor insufficient?

A: `Contributor` grants create, read, update, delete on resources but explicitly excludes `Microsoft.Authorization/*` operations. Creating a policy assignment is an authorization operation, not a resource operation. `Resource Policy Contributor` adds `Microsoft.Authorization/policyAssignments/write` which is what Terraform needs to create the assignment. You grant it at subscription scope because policy definitions are subscription-level resources even when assigned to a resource group.

---

### Step 3 — Policy Definitions

**Why this step exists:**
A policy definition is a rule written down. It does nothing by itself. Think of it as legislation that has been drafted but not yet signed into law. The enforcement comes in Step 4 when you assign it.

Each definition has two parts that work together. The `policy_rule` contains the `if` condition and the `then` effect. The `if` evaluates ARM resource properties. The `then` specifies what happens when the condition is true — Deny, Audit, DeployIfNotExists, Modify, or Append.

**Why one definition per required tag instead of one definition for all tags:**
Azure Policy evaluates one condition per definition. You cannot write "if ANY of these tags is missing, deny." You write one definition per tag. Each definition is a separate rule with its own compliance tracking. In the Azure Policy compliance dashboard, you see exactly which tag is missing on which resource — not just "tags are wrong." This granularity matters for debugging and remediation.

**The `mode` property matters:**
`Indexed` means the policy only evaluates resource types that support tags and locations — most compute and storage resources. `All` evaluates every resource type including resource groups and subscriptions themselves. Using `All` for a tag policy would apply it to management plane objects like deployments and policy assignments themselves, which would cause circular failures. `Indexed` is correct for resource-level governance.

**The `allOf` operator in deny_public_storage:**
```json
"allOf": [
  { "field": "type", "equals": "Microsoft.Storage/storageAccounts" },
  { "field": "Microsoft.Storage/storageAccounts/publicNetworkAccess", "equals": "Enabled" }
]
```
Both conditions must be true for the Deny to trigger. The type check is mandatory. Without it, the policy evaluates `publicNetworkAccess` against every resource type. Resources without that field return null which does not equal "Enabled" — they pass safely. But other resource types that legitimately expose a `publicNetworkAccess` field could be blocked unintentionally. The type check makes the policy surgical — it only fires on storage accounts.

**Interview question you must be able to answer:**

Q: What is the difference between `Deny` and `Audit` effect in Azure Policy, and when would you use each?

A: `Deny` rejects the resource creation or modification request at the ARM API level. The resource is never created. The caller gets a `RequestDisallowedByPolicy` error immediately. Use Deny for hard security requirements where non-compliance is unacceptable — public storage, wrong region, missing mandatory tags. `Audit` allows the resource to be created but marks it as non-compliant in the Azure Policy compliance dashboard. No blocking occurs. Use Audit when you want visibility first — understand the scope of non-compliance before enforcing it. The typical progression in production is: deploy as Audit → review compliance data for 2-4 weeks → escalate to Deny once you understand the impact.

---

### Step 4 — Policy Initiative + Assignments

**Why this step exists:**
You now have six policy definitions sitting at subscription level doing nothing. The initiative bundles them. The assignment makes them enforceable at a specific scope.

**Why use an initiative instead of assigning definitions directly:**
Assigning six definitions individually means six assignments to manage, audit, update, and report on. When you add a seventh policy, you create a seventh assignment. In an enterprise with 50 policies across 20 resource groups, that is 1000 individual assignments to manage. An initiative is one assignment that contains all policies. One compliance score. One place to add new policies. One assignment to update when a policy changes.

The initiative exposes parameters that flow down to definitions. The `allowedLocations` parameter is defined at the initiative level and passed to the `allowed_locations` definition at assignment time. This means the same initiative can be assigned to a dev resource group with `["centralindia"]` and a production resource group with `["centralindia", "westeurope"]` — same policy logic, different values.

**Why `azurerm_resource_group_policy_assignment` and not `azurerm_policy_assignment`:**
AzureRM 3.x removed the generic `azurerm_policy_assignment` resource and split it into four scope-specific resources:
- `azurerm_resource_group_policy_assignment` — assigns at RG scope
- `azurerm_subscription_policy_assignment` — assigns at subscription scope
- `azurerm_management_group_policy_assignment` — assigns at management group scope
- `azurerm_resource_policy_assignment` — assigns at individual resource scope

Using the wrong resource type causes "Invalid resource type" at validate — the provider does not recognise the resource name. Always check which scope your assignment targets before choosing the resource type.

**Why the SystemAssigned identity on the assignment:**
Today's policies use `Deny` and `Audit` — both are passive evaluations that require no identity. The identity block is included as preparation for `DeployIfNotExists` escalation. When you escalate the diagnostic settings policy from `Audit` to `DeployIfNotExists`, Azure needs an identity to call the ARM API and deploy the diagnostic setting automatically. Without the identity and the Contributor role assignment, `DeployIfNotExists` fails with 403 silently — the policy evaluation succeeds but the remediation never executes. Including the identity now means the escalation is one word change in the effect, not a structural refactor of the assignment.

**The scope question you must understand:**
The assignment is scoped to `rg-governance-day14`. A developer creates `rg-dev-experiment` and deploys a public storage account there. Your policy does NOT block it. Policy enforcement only applies within the assigned scope. To cover the entire subscription, change `resource_group_id` to `/subscriptions/${var.subscription_id}` in the assignment. This is the single most important operational decision in governance — scope determines what is actually protected.

**Interview question you must be able to answer:**

Q: You assign a Deny policy at resource group scope. A developer creates a new resource group and deploys non-compliant resources there. Your policy does not block it. How do you fix this without rewriting the policy definition?

A: Change the assignment scope from resource group to subscription. The policy definition stays identical. The assignment is updated to target `/subscriptions/<id>` instead of the resource group ID. Now every resource group in the subscription is covered regardless of its name. You can use exclusions on the assignment to exempt specific resource groups that legitimately need different rules — for example, excluding a sandbox resource group from the allowed locations policy so developers can experiment in any region.

---

### Step 5 — Root Module Wiring + Pipeline Execution

**Why this step exists:**
The root `main.tf` is the orchestrator. It creates the resource group — which is also the scope of the policy assignment — and passes that resource group's ID into the governance module. This creates a dependency: the resource group must exist before the policy assignment can be scoped to it. Terraform resolves this automatically through the reference `resource_group_id = azurerm_resource_group.main.id`.

**The variable hanging problem:**
`terraform.tfvars` is gitignored. The pipeline agent never receives it. When Terraform cannot find variable values, it prompts interactively — waiting for keyboard input that never comes in a pipeline. The pipeline hangs until it times out.

The fix is `-var` flags in the plan command:
```bash
terraform plan \
  -var="resource_group_name=rg-governance-day14" \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  ...
```

This is the correct pattern for all pipelines. `terraform.tfvars` is for local development. Pipelines get values from `-var` flags, environment variables (`TF_VAR_*`), or Azure DevOps Variable Groups. Never commit tfvars containing real values.

**The state lock problem:**
When a pipeline crashes mid-execution — timeout, agent failure, cancelled run — Terraform does not release the state lock. The lock is a blob lease on the state file in Azure Storage. The next pipeline run hits "state blob is already locked" and fails immediately.

Fix with:
```bash
az storage blob lease break --blob-name day14.terraform.tfstate --container-name tfstate --account-name sttfstateday14
```

Always verify no other pipeline is genuinely running before breaking a lock. Breaking a lock that belongs to an active run causes state corruption.

**Interview question you must be able to answer:**

Q: Your Terraform pipeline fails with "state blob is already locked." How do you diagnose whether it is safe to break the lock, and what command do you use?

A: First check the pipeline run history in Azure DevOps. If you see a currently running pipeline against the same workspace, do not break the lock — that is a live run. If all previous runs are complete or failed, the lock is stale from a crashed run. Check the lock info which shows the operation type, timestamp, and agent that holds it. If the timestamp is from a run that no longer exists in the pipeline history, it is safe to break. Use `az storage blob lease break` against the specific blob. Never use `-lock=false` in production as a workaround — it bypasses the safety mechanism entirely and risks concurrent state writes.

---

## Compliance Test — Confirming Enforcement Works

After apply, run this command — it should fail:

```bash
az storage account create --name testpublicday14 --resource-group rg-governance-day14 --location eastus --sku Standard_LRS
```

This fails on three policies simultaneously:
1. `day14-allowed-locations` — `eastus` is not in `[centralindia, westeurope]`
2. `day14-require-tag-environment` — no `environment` tag provided
3. `day14-require-tag-owner` — no `owner` tag provided
4. `day14-require-tag-costcenter` — no `costCenter` tag provided

Azure reports the first violation it hits. Fix the location, still blocked by missing tags. Add tags, if public access is default-enabled on the account, blocked by `deny-public-storage`. You must satisfy all policies simultaneously for the resource to be created.

A fully compliant command looks like:
```bash
az storage account create --name testcompliantday14 --resource-group rg-governance-day14 --location centralindia --sku Standard_LRS --public-network-access Disabled --tags environment=day14 owner=devops-learning costCenter=training
```

---

## Policy Effects — Reference

| Effect | What Happens | Requires Identity | When to Use |
|---|---|---|---|
| Deny | Request rejected. Resource not created. | No | Hard security requirements |
| Audit | Resource created, flagged non-compliant | No | Visibility before enforcement |
| DeployIfNotExists | Auto-deploys remediation resource | Yes — Contributor | Ensure companion resources exist |
| Modify | Auto-adds or changes resource properties | Yes — Contributor | Auto-tagging, auto-enabling settings |
| Append | Adds fields to resource before creation | No | Force additional properties |

---

## Errors Hit and Why They Matter

| Error | Root Cause | Fix | Lesson |
|---|---|---|---|
| Module not installed — symlink error | `modules/governance/main.tf` contained a `module` block calling itself | Replace with single `data` block | Root calls module. Module never calls itself. |
| Invalid resource type `azurerm_policy_assignment` | Resource removed in AzureRM 3.x | Replace with `azurerm_resource_group_policy_assignment` | Provider version matters — check resource exists before writing |
| State blob already locked | Previous pipeline crashed without releasing lease | `az storage blob lease break` | Always check for live runs before breaking a lock |
| Pipeline hanging at `var.resource_group_name` | `terraform.tfvars` is gitignored — pipeline agent has no variable values | Pass values via `-var` flags in plan command | Pipelines never use tfvars — use `-var` flags or Variable Groups |

---

## Concepts You Can Now Answer

**What Azure Policy is at the API level:**
A policy evaluation engine inside Azure Resource Manager. Every resource creation and modification request passes through it before ARM acts on the request. It is not a monitoring layer — it is a gate at the API entry point.

**Why governance-as-code matters:**
If someone weakens a policy — removes Deny, expands allowed regions, drops a required tag — that change creates a PR, requires a review, and is logged in git history forever. The same accountability that applies to infrastructure code applies to the rules governing infrastructure. Manual portal policy changes leave no audit trail and cannot be reviewed before taking effect.

**Difference between policy definition, initiative, and assignment:**
Definition is the rule. Initiative is a bundle of rules. Assignment is what makes rules enforceable at a specific scope. You can have the best definitions in the world — they enforce nothing until assigned.

**Why scope matters more than the policy itself:**
The strongest policy assigned to the wrong scope protects nothing. A subscription-level assignment protects everything. A resource-group-level assignment protects only that group. Understanding scope is the operational decision that determines what your governance actually covers.

**What happens to resources created before a policy is assigned:**
They are not retroactively destroyed. They are evaluated against the policy and marked as non-compliant in the compliance dashboard. Only new creation and modification requests are blocked by Deny policies. To remediate existing non-compliant resources you use `DeployIfNotExists` with a remediation task, or manual remediation, or a separate cleanup pipeline.

**Why EU companies care about this:**
GDPR Article 25 requires Data Protection by Design — privacy controls built into systems by default. A Deny policy on public storage is Data Protection by Design. You cannot accidentally expose personal data because the platform makes it technically impossible. ISO 27001 requires demonstrable access controls and network segmentation. Terraform + Policy + git history + pipeline logs is the demonstration. It is not a screenshot of a portal setting. It is a complete, auditable, version-controlled enforcement chain.