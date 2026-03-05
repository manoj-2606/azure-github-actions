resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  # ── Zero public exposure ──────────────────────────────────
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  # ── Security hardening ────────────────────────────────────
  min_tls_version           = "TLS1_2"
  shared_access_key_enabled  = false

  # ── Deny all traffic by default ───────────────────────────
  # Private endpoint is the ONLY allowed path
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}