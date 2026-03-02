# ============================================================
# Day 11 — Root Main
# Wires together: identity → rbac → keyvault
# All resources in Central India | rg-day11-identity
# ============================================================

# Pull current subscription + tenant info (needed for scopes)
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# ============================================================
# STORAGE ACCOUNT — for RBAC scoping exercise
# Managed Identity will get Storage Blob Data Contributor here
# ============================================================
resource "azurerm_storage_account" "app" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# ============================================================
# MODULE: identity
# Creates User-Assigned Managed Identity
# Outputs principal_id → consumed by rbac module below
# ============================================================
module "identity" {
  source = "./modules/identity"

  identity_name       = "id-${var.project_name}-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ============================================================
# MODULE: keyvault
# Creates Key Vault with RBAC authorization enabled
# Outputs id → used as scope in rbac module below
# ============================================================
module "keyvault" {
  source = "./modules/keyvault"

  key_vault_name      = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ============================================================
# MODULE: rbac
# Assigns multiple roles via for_each
# This is the core of Day 11 — notice:
#   - Each role has a unique label (map key)
#   - Each role has its own SCOPE (not subscription-wide)
#   - Roles are least-privilege (no Owner, no Contributor)
# ============================================================
module "rbac" {
  source = "./modules/rbac"

  role_assignments = {

    # ✅ Exercise 1 — Storage Blob Data Contributor
    # Scope: specific storage account (NOT subscription)
    # Why: Identity only needs blob access, not full storage control
    "storage_blob_contributor" = {
      principal_id         = module.identity.principal_id
      role_definition_name = "Storage Blob Data Contributor"
      scope                = azurerm_storage_account.app.id
    }

    # ✅ Exercise 2 — Reader at Resource Group level
    # Scope: resource group (NOT subscription)
    # Why: Identity needs to see resources but not modify them
    "rg_reader" = {
      principal_id         = module.identity.principal_id
      role_definition_name = "Reader"
      scope                = data.azurerm_resource_group.main.id
    }

    # ✅ Part 4 — Key Vault Secrets User
    # Scope: specific Key Vault (NOT resource group)
    # Why: Identity only needs to READ secrets, not manage vault
    "kv_secrets_user" = {
      principal_id         = module.identity.principal_id
      role_definition_name = "Key Vault Secrets User"
      scope                = module.keyvault.id
    }
  }

  # rbac module depends on identity + keyvault existing first
  depends_on = [
    module.identity,
    module.keyvault
  ]
}