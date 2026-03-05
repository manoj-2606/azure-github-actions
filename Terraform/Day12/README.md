# Day 12 — Secure Network Architecture (Enterprise Level)
## Advanced Azure Networking: Production Topology Design

---

## What This Project Does

This project builds a **production-grade secure Azure network topology** using:
- Hub-and-Spoke VNet architecture
- VNet Peering (Hub ↔ Spoke)
- Private Endpoint for Azure Storage Account
- Private Endpoint for Azure Key Vault
- Private DNS Zone linking
- NSG hardening (least privilege)
- All resources with **zero public exposure**

Everything is deployed via **Azure DevOps YAML pipeline** using Terraform and OIDC authentication.

---

## Folder Structure

```
day12-secure-network/
├── README.md                          ← You are here
├── goals.txt                          ← Day 12 learning goals
├── commands.txt                       ← All commands used with explanations
├── terraform/
│   ├── main.tf                        ← Root module: wires all modules together
│   ├── variables.tf                   ← All input variables
│   ├── outputs.tf                     ← Outputs: IPs, resource IDs, DNS info
│   ├── providers.tf                   ← Azure provider + OIDC auth config
│   ├── backend.tf                     ← Remote state config (Azure Storage)
│   └── modules/
│       ├── networking/
│       │   ├── main.tf                ← Hub VNet, Spoke VNet, Subnets, Peering, NSG
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── storage/
│       │   ├── main.tf                ← Storage Account, public access disabled
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── keyvault/
│       │   ├── main.tf                ← Key Vault, public access disabled
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── private-endpoints/
│           ├── main.tf                ← Private Endpoints + Private DNS Zones for both
│           ├── variables.tf
│           └── outputs.tf
└── pipelines/
    ├── azure-pipelines.yml            ← Main pipeline: triggers plan + apply
    └── templates/
        ├── terraform-plan.yml         ← Reusable template: terraform init + plan
        ├── terraform-apply.yml        ← Reusable template: terraform apply
        └── terraform-destroy.yml      ← Reusable template: terraform destroy (manual trigger)
```

---

## Architecture

```
                        ┌─────────────────────────────────┐
                        │         Hub VNet                 │
                        │    (10.0.0.0/16)                 │
                        │  ┌─────────────────────┐         │
                        │  │  hub-subnet          │         │
                        │  │  (10.0.1.0/24)       │         │
                        │  └─────────────────────┘         │
                        └────────────┬────────────────────-┘
                                     │  VNet Peering
                        ┌────────────▼────────────────────-┐
                        │         Spoke VNet                │
                        │    (10.1.0.0/16)                  │
                        │  ┌─────────────────────┐          │
                        │  │  app-subnet          │          │
                        │  │  (10.1.1.0/24)       │          │
                        │  └─────────────────────┘          │
                        │  ┌─────────────────────┐          │
                        │  │  data-subnet         │          │
                        │  │  (10.1.2.0/24)       │          │
                        │  └─────────────────────┘          │
                        │  ┌─────────────────────┐          │
                        │  │  pe-subnet           │ ◄──── Private Endpoints live here
                        │  │  (10.1.3.0/24)       │          │
                        │  └─────────────────────┘          │
                        └──────────────────────────────────-┘
                                     │
                   ┌─────────────────┴──────────────────┐
                   │                                     │
        ┌──────────▼──────────┐             ┌───────────▼──────────┐
        │  Storage Account    │             │     Key Vault         │
        │  Public: DISABLED   │             │  Public: DISABLED     │
        │  Private EP: ✓      │             │  Private EP: ✓        │
        │  Private DNS: ✓     │             │  Private DNS: ✓       │
        └─────────────────────┘             └──────────────────────┘
```

---

## Prerequisites

- Azure subscription
- Azure DevOps organization + project
- Service Principal with OIDC (federated credentials) configured
- Terraform backend storage account pre-created (bootstrap step)
- Azure DevOps variable group named `day12-vars` with:
  - `ARM_CLIENT_ID`
  - `ARM_TENANT_ID`
  - `ARM_SUBSCRIPTION_ID`
  - `BACKEND_RESOURCE_GROUP`
  - `BACKEND_STORAGE_ACCOUNT`
  - `BACKEND_CONTAINER`

---

## Region

All resources deployed to: **Central India** (`centralindia`)

---

## How to Run

1. Push this repo to Azure DevOps
2. Create pipeline from `pipelines/azure-pipelines.yml`
3. Run pipeline — it will plan and apply automatically
4. To destroy: manually trigger the destroy pipeline stage

---

## What You Learn

| Concept | Why It Matters |
|---|---|
| Hub-and-Spoke VNet | Standard enterprise topology — one hub controls routing |
| VNet Peering | Connect VNets without public internet |
| Private Endpoint | Service accessible only inside VNet — no public IP |
| Private DNS Zone | Resolves service name to private IP inside VNet |
| NSG Hardening | Firewall rules at subnet level |
| Public Access Disabled | Zero public exposure — EU compliance requirement |