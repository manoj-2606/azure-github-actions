# Day 14 — Governance & Policy Enforcement

> Security rules that depend on humans following them are not rules. They are suggestions. Azure Policy makes compliance technically impossible to bypass.

---

## Why This Day Exists

You have built 13 days of secure infrastructure. Proper RBAC. Private endpoints. Monitoring. Zero public exposure. All of it can be undone in 30 seconds by a new engineer who does not know the rules or does not follow them.

Day 14 makes non-compliance technically impossible. Azure Policy evaluates every resource creation and modification at the Azure Resource Manager API level. It does not matter whether the request comes from Terraform, az cli, the Azure Portal, or a REST API call. The policy evaluation happens before the resource is created.

---

## Target Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                           │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────────┐  │
│   │  Policy Initiative: day14-governance-baseline               │  │
│   │                                                             │  │
│   │  ┌──────────────────┐  ┌──────────────────┐                │  │
│   │  │ Require Tags     │  │ Allowed Locations │                │  │
│   │  │ Effect: Deny     │  │ Effect: Deny      │                │  │
│   │  └──────────────────┘  └──────────────────┘                │  │
│   │  ┌──────────────────┐  ┌──────────────────┐                │  │
│   │  │ Deny Public      │  │ Audit Diagnostics │                │  │
│   │  │ Storage          │  │ Effect: Audit     │                │  │
│   │  │ Effect: Deny     │  └──────────────────┘                │  │
│   │  └──────────────────┘                                       │  │
│   └─────────────────────────────────────────────────────────────┘  │
│                         │                                           │
│                         │ Assigned at scope:                        │
│                         ▼                                           │
│   ┌─────────────────────────────────────────────────────────────┐  │
│   │  rg-governance-day14                                        │  │
│   │                                                             │  │
│   │  Any resource created here is evaluated against all         │  │
│   │  4 policies before Azure creates it.                        │  │
│   │                                                             │  │
│   │  Non-compliant request → Rejected by ARM → Error in         │  │
│   │  terraform apply output                                     │  │
│   └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure
```
Day14/
├── .gitignore
├── azure-pipelines.yml
├── commands.txt
├── goals.txt
├── purpose.txt
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── modules/
│   └── governance/
│       ├── main.tf
│       ├── policy_definitions.tf
│       ├── policy_assignments.tf
│       ├── policy_initiative.tf
│       ├── variables.tf
│       └── outputs.tf
└── pipelines/
    ├── templates/
    │   ├── tf-init.yml
    │   ├── tf-plan.yml
    │   └── tf-apply.yml
    └── vars/
            centralindia.yml
```

---

## Policy Effects — Know These Before You Write Any Policy

| Effect | What Happens | When to Use |
|---|---|---|
| Deny | Request rejected. Resource not created. | Hard requirements — public storage, wrong region |
| Audit | Resource created but flagged non-compliant | Soft requirements — visibility without blocking |
| DeployIfNotExists | Azure auto-deploys a remediation resource | Ensure companion resources exist — e.g., diagnostic settings |
| Modify | Azure auto-adds or changes properties | Auto-tagging, auto-enabling settings |
| Append | Adds fields before creation | Force additional properties |

Today: Deny for tags, locations, public storage. Audit for diagnostic settings.

---

## Policies Built Today

### 1 — Require Mandatory Tags (Deny)
Every resource must have `environment`, `owner`, `costCenter` tags.
Without tags, cost attribution is impossible. You cannot answer "who owns this resource?" or "what environment is this?" in an incident.

### 2 — Restrict Allowed Locations (Deny)
Resources can only be created in `centralindia` or `westeurope`.
EU data residency requirements prohibit storing data in non-EU regions without explicit consent. This policy makes it technically impossible to accidentally deploy to `eastus` or `southeastasia`.

### 3 — Deny Public Storage Accounts (Deny)
`public_network_access_enabled` must be `false`.
This policy makes Day 12's private endpoint architecture mandatory — not optional.

### 4 — Audit Diagnostic Settings (Audit)
Resources should send logs to Log Analytics.
Starts as Audit (visibility) — escalate to DeployIfNotExists in production to auto-remediate.

---

## Pipeline Flow
```
Push to main
     │
     ▼
Terraform Init → connects to backend
     │
     ▼
Terraform Fmt Check + Validate
     │
     ▼
Terraform Plan → shows all policy resources to be created
     │
     ▼ (main branch only)
Terraform Apply → policies deployed to Azure
     │
     ▼
Compliance Test → attempt non-compliant resource → confirmed blocked
```

---

## Concepts You Must Explain After Day 14

**What is the difference between Deny and Audit?**
Deny blocks creation. Audit allows creation but marks the resource non-compliant in the policy dashboard. Use Deny for hard security requirements. Use Audit when you want visibility first before blocking.

**What is a Policy Initiative?**
A bundle of policy definitions assigned together as a single unit. In production, organisations have 20-100 policies. Assigning each individually is unmanageable. An initiative groups them. One assignment covers all policies in the set.

**What scope should you assign policies at?**
Subscription scope affects everything in the subscription. Resource group scope affects only that resource group. Management group scope affects multiple subscriptions. Start at resource group scope for testing, escalate to subscription or management group for production enforcement.

**Why does Terraform honour Azure Policy?**
Terraform calls the Azure Resource Manager API to create resources. Azure Policy is evaluated by ARM before any resource is created. Terraform does not bypass policy — it is subject to the same API enforcement as every other tool. A Deny policy causes the ARM API to return a 403 RequestDisallowedByPolicy error, which Terraform surfaces as an apply failure.

**Why is governance-as-code important?**
Policy definitions in Terraform are version-controlled, reviewed in PRs, and deployed through the same pipeline as infrastructure. If someone weakens a policy — removes the Deny effect, expands the allowed regions — that change creates a PR, requires a review, and is logged in git history forever. Governance-as-code applies the same accountability to rules as to resources.