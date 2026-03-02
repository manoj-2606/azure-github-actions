# ============================================================
# MODULE: keyvault
# Purpose: Creates Azure Key Vault with RBAC authorization
#
# WHY enable_rbac_authorization = true:
# - Modern model (Access Policies = legacy)
# - Same RBAC system as all other Azure resources
# - Auditable via Azure Policy
# - Roles assigned via modules/rbac/ — consistent pattern
# - No mixing of two permission systems
#
# WHO can access secrets is controlled in root main.tf
# by passing roles into the RBAC module — NOT here.
# ============================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                        = var.key_vault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  # THIS IS THE CRITICAL LINE — switches from Access Policies to RBAC
  enable_rbac_authorization   = true

  # Security hardening settings
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false   # set true in prod to prevent accidental permanent delete

  network_acls {
    default_action = "Allow"   # tighten to "Deny" + ip_rules in prod
    bypass         = "AzureServices"
  }

  tags = var.tags
}