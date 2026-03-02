# ============================================================
# MODULE: identity
# Purpose: Creates a User-Assigned Managed Identity ONLY
# No role assignments here — that lives in modules/rbac/
# Identity = WHO you are. RBAC = WHAT you can do.
# ============================================================

resource "azurerm_user_assigned_identity" "this" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
