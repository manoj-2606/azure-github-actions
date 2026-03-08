# Day 13 — Platform Monitoring & Observability

> Infrastructure without monitoring is not infrastructure. It is hope.

---

## What You Are Building

A centralized observability pipeline using Terraform that sends logs and metrics
from every critical Azure resource into a single Log Analytics Workspace.

---

## Target Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                           │
│                                                                     │
│   ┌─────────────┐   ┌──────────────┐   ┌───────┐   ┌──────────┐   │
│   │  Key Vault  │   │   Storage    │   │  VNet │   │   NSG    │   │
│   │             │   │   Account    │   │       │   │          │   │
│   └──────┬──────┘   └──────┬───────┘   └───┬───┘   └────┬─────┘   │
│          │                 │               │             │         │
│          │  Diagnostic     │  Diagnostic   │  Diagnostic │         │
│          │  Settings       │  Settings     │  Settings   │         │
│          └────────────┬────┘               └──────┬──────┘         │
│                       │                           │                 │
│          Activity Logs│                           │                 │
│          (Subscription)◄──────────────────────────┘                │
│                       │                                             │
│                       ▼                                             │
│          ┌────────────────────────┐                                 │
│          │   Log Analytics        │                                 │
│          │   Workspace            │◄── KQL Queries                  │
│          │                        │    AzureDiagnostics | take 10   │
│          │   - AuditEvent logs    │    AzureActivity | take 10      │
│          │   - AllLogs            │                                 │
│          │   - AllMetrics         │                                 │
│          └────────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
day13-monitoring/
├── main.tf                          # Root: wires all modules together
├── variables.tf                     # Input variables
├── outputs.tf                       # Exposed values
├── providers.tf                     # AzureRM + version locks
├── terraform.tfvars                 # Your actual values (not in git)
└── modules/
    └── monitoring/
        ├── main.tf                  # Log Analytics Workspace
        ├── diagnostic_keyvault.tf   # Diagnostic settings → Key Vault
        ├── diagnostic_storage.tf    # Diagnostic settings → Storage
        ├── diagnostic_network.tf    # Diagnostic settings → NSG + VNet
        ├── activity_logs.tf         # Subscription-level activity logs
        ├── variables.tf             # Module input variables
        └── outputs.tf               # workspace_id, workspace_name
```

---

## Core Concepts

### Log Analytics Workspace
The central brain. Every resource ships logs here.
Query surface via KQL (Kusto Query Language).

```
Azure Resource → Diagnostic Setting → Log Analytics Workspace → KQL Query
```

### Diagnostic Settings
A Terraform resource (`azurerm_monitor_diagnostic_setting`) that acts as
a pipe between a resource and a log destination.

Without it: logs exist but are discarded internally.
With it: logs flow to your workspace.

### Log Categories

| Category | What it captures |
|---|---|
| AuditEvent | Who accessed what in Key Vault |
| AllLogs | Every operation log for a resource |
| AllMetrics | Numerical metrics (latency, errors, throughput) |

### Activity Logs vs Diagnostic Logs

```
Activity Logs          = WHO did WHAT at the SUBSCRIPTION level
                         (control plane: create, delete, modify resources)

Diagnostic Logs        = WHAT HAPPENED inside a specific resource
                         (data plane: secret read, blob downloaded, packet dropped)
```

---

## Resources Created

| Resource | Type | Purpose |
|---|---|---|
| `azurerm_log_analytics_workspace` | Monitoring | Central log store |
| `azurerm_monitor_diagnostic_setting` (kv) | Diagnostics | Key Vault audit logs |
| `azurerm_monitor_diagnostic_setting` (storage) | Diagnostics | Storage access logs |
| `azurerm_monitor_diagnostic_setting` (nsg) | Diagnostics | NSG flow logs |
| `azurerm_monitor_diagnostic_setting` (activity) | Diagnostics | Subscription activity |
| `azurerm_key_vault` | Security | Secret store (log source) |
| `azurerm_storage_account` | Storage | Blob storage (log source) |
| `azurerm_network_security_group` | Network | Traffic rules (log source) |
| `azurerm_virtual_network` | Network | VNet (log source) |

---

## Key Terraform Resources

### Log Analytics Workspace
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

### Diagnostic Setting (example)
```hcl
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

---

## Validation — KQL Queries

After `terraform apply`, run these in:
**Azure Portal → Log Analytics Workspace → Logs**

```kql
// See all diagnostic data
AzureDiagnostics
| take 10

// Key Vault audit events specifically
AzureDiagnostics
| where ResourceType == "VAULTS"
| take 10

// All subscription-level activity
AzureActivity
| take 10

// Destructive operations
AzureActivity
| where OperationNameValue contains "delete"
| project TimeGenerated, Caller, OperationNameValue, ResourceGroup
| take 20
```

---

## Concepts You Must Be Able to Explain After Today

**Q: Difference between metrics vs logs?**
Metrics are numerical time-series data (CPU %, request count).
Logs are structured event records (who did what, when, result).

**Q: What do diagnostic settings actually do?**
They create a forwarding rule from a resource's internal telemetry
to an external destination like Log Analytics.

**Q: Why should monitoring be centralized?**
Cross-resource correlation, single compliance surface,
no fragmented visibility, cost control.

**Q: What logs help detect security incidents?**
AuditEvent (Key Vault), AzureActivity (control plane changes),
NSG flow logs (suspicious traffic), StorageBlobLogs (unauthorized access).

**Q: Why do activity logs matter?**
They record every resource mutation at subscription level.
Essential for "who deleted production at 3am" investigations.

---

## Why This Matters for EU / Finland

| Regulation | Requirement | How This Satisfies It |
|---|---|---|
| GDPR Art. 32 | Technical security measures | Audit trails for all data access |
| NIS2 | Monitoring of critical systems | Centralized log pipeline |
| ISO 27001 | Audit logging | Activity + diagnostic logs retained |

---

## Steps Overview

| Step | What Happens |
|---|---|
| 1 | Project structure + providers |
| 2 | Monitoring module — Log Analytics Workspace |
| 3 | Root configuration wires modules |
| 4 | Diagnostic settings — Key Vault |
| 5 | Diagnostic settings — Storage Account |
| 6 | Diagnostic settings — NSG + VNet |
| 7 | Subscription Activity Logs |
| 8 | terraform plan + apply |
| 9 | KQL validation in Azure Portal |