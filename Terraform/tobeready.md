# Terraform Learning Roadmap — Finland Ready

A structured, no-fluff roadmap for becoming a production-grade Terraform / Cloud Infrastructure Engineer.

---

## Where You Are Right Now

After Day 12, you have covered the following:

| Topic | Status |
|---|---|
| Terraform Fundamentals | Done |
| Modules | Done |
| Dynamic Infrastructure | Done |
| Remote State | Done |
| Environment Isolation | Done |
| CI/CD Pipelines | Done |
| OIDC Authentication | Done |
| RBAC Automation | Done |
| Managed Identities | Done |
| Private Networking | Done |
| Hub-Spoke Topology | Done |
| Private Endpoints | Done |
| Private DNS Zones | Done |

This covers **70–75% of Terraform knowledge used in real companies.**

What you do not yet have is platform-level architecture skills. That is the next phase.

---

## The Honest Skill Gap

"Finland ready" means Cloud Infrastructure Engineer — not just Terraform proficiency.

| Area | Priority |
|---|---|
| AKS Infrastructure with Terraform | Very High |
| Monitoring + Observability | High |
| Azure Policy Enforcement | High |
| Cost Governance | Medium |
| Multi-Region Architecture | Medium |
| Disaster Recovery Patterns | Medium |
| Testing Terraform (Terratest) | Medium |
| Platform Architecture Thinking | Very High |

**Terraform Tool Mastery: ~80% complete.**
The remaining gap is infrastructure engineering depth, not tool syntax.

---

## Roadmap

### Phase 1 — Foundations
**Days 1–12 (Complete)**

Core Terraform mechanics, state management, modules, networking, CI/CD, and authentication patterns. You have done this.

---

### Phase 2 — Professional Terraform
**Days 13–22 (~10 days)**

- Advanced module patterns and reusable module composition
- Workspaces vs folder-based environment strategy (and when each is appropriate)
- Remote backend configuration, state locking, and state migration
- Dynamic blocks and complex variable structures
- Lifecycle rules (`create_before_destroy`, `prevent_destroy`, `ignore_changes`)
- Importing existing infrastructure into state
- State manipulation (`terraform state mv`, `rm`, `pull`, `push`)
- CI/CD pipeline integration (GitHub Actions / Azure DevOps)
- Linting and formatting (`terraform fmt`, `tflint`, `checkov`)
- Secrets handling (Key Vault integration, no hardcoded values)

---

### Phase 3 — Real-World Project
**Days 23–35 (~12–14 days)**

Build one serious, portfolio-grade project. This is what recruiters evaluate.

**Example architecture:**

```
/project
  /modules
    /networking
    /aks
    /monitoring
    /security
  /environments
    /dev
    /staging
    /prod
  /pipelines
  /tests
```

**Project must include:**

- Full VNet architecture with Hub-Spoke
- NSGs and route tables
- AKS cluster with node pools
- Monitoring stack (Azure Monitor, Log Analytics, alerts)
- Backend state in Azure Storage with locking
- CI/CD pipelines with environment promotion
- Multi-environment configuration
- RBAC and managed identity wiring

No shortcuts. No half-built repos. Recruiters look at GitHub.

---

## Time Estimate to Finland Ready

| Condition | Timeline |
|---|---|
| 2–3 hours daily, hands-on only | 20–25 focused days from now |
| Tutorial hopping, passive watching | Indefinitely |

You already built the fundamentals correctly. The path is short — if you stay off YouTube and build.

---

## What Will Kill Your Progress

- Watching tutorials instead of writing code
- Switching between tools before mastering the current one
- Building half a project and moving on
- Treating documentation reading as progress

**The only metric that matters: does your infrastructure deploy, behave correctly, and survive a code review?**

---

## Folder Structure (This Repo)

```
/terraform
  /modules          # Reusable infrastructure components
  /environments     # Per-environment root configs (dev, staging, prod)
  /pipelines        # CI/CD definitions
  /tests            # Terratest or policy tests
  /docs             # Architecture diagrams, ADRs
  README.md
```

---

## Standards Enforced

- `terraform fmt` on every commit
- `tflint` clean before merge
- No secrets in state or code — Key Vault only
- All resources tagged: `environment`, `owner`, `project`
- Remote state mandatory — local state is not acceptable

---

## Current Phase

**Phase 2 — Professional Terraform**

Next milestone: Complete AKS module with monitoring and deploy it across two environments via pipeline.