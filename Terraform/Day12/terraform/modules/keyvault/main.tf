# Pull current client identity so we can give pipeline SP access
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  # ── Zero public exposure ──────────────────────────────────
  public_network_access_enabled = false

  # ── Soft delete + purge protection ───────────────────────
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  # Note: purge_protection_enabled = false so Terraform destroy works cleanly
  # In production, set this to true

  # ── Deny all network traffic by default ──────────────────
  # Private endpoint is the ONLY allowed path
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  # ── Give the pipeline SP access to manage secrets ────────
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Recover"
    ]
  }

  tags = var.tags
}