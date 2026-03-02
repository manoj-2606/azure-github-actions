# ============================================================
# MODULE: rbac
# Purpose: Creates role assignments dynamically using for_each
#
# WHY for_each here:
# One managed identity often needs multiple roles at different
# scopes. Instead of copy-pasting role_assignment blocks,
# we pass a map and Terraform handles all of them.
#
# Real-world example:
#   identity needs:
#     - Storage Blob Data Contributor on storage account
#     - Key Vault Secrets User on key vault
#     - Reader on resource group
#   = 3 entries in the map = 3 role assignments, zero duplication
# ============================================================

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
  scope                = each.value.scope

  # skip_service_principal_aad_check:
  # Set true for Managed Identities to avoid AAD propagation delays
  # Without this, Terraform sometimes fails on fresh identities
  skip_service_principal_aad_check = true
}
