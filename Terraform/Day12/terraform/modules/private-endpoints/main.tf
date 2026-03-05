# ============================================================
# PRIVATE ENDPOINT — Storage Account (Blob)
# ============================================================

resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${var.storage_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.storage_account_name}"
    private_connection_resource_id = var.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
    # subresource = blob means we are creating a private endpoint for Blob storage
    # Other options: file, queue, table, dfs — one private endpoint per subresource
  }

  private_dns_zone_group {
    name                 = "dns-group-storage"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# ============================================================
# PRIVATE ENDPOINT — Key Vault
# ============================================================

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = var.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
    # subresource = vault is the only option for Key Vault
  }

  private_dns_zone_group {
    name                 = "dns-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# ============================================================
# PRIVATE DNS ZONE — Storage Blob
# This zone must match exactly: privatelink.blob.core.windows.net
# Azure uses this name to intercept DNS queries and return private IPs
# ============================================================

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ============================================================
# PRIVATE DNS ZONE — Key Vault
# This zone must match exactly: privatelink.vaultcore.azure.net
# ============================================================

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ============================================================
# DNS ZONE LINKS — Storage DNS Zone → Hub VNet
# Without this link, Hub VNet resources cannot resolve the private IP
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "storage_hub" {
  name                  = "dns-link-storage-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ============================================================
# DNS ZONE LINKS — Storage DNS Zone → Spoke VNet
# Without this link, Spoke VNet resources cannot resolve the private IP
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "storage_spoke" {
  name                  = "dns-link-storage-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ============================================================
# DNS ZONE LINKS — Key Vault DNS Zone → Hub VNet
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "dns-link-keyvault-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# ============================================================
# DNS ZONE LINKS — Key Vault DNS Zone → Spoke VNet
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  name                  = "dns-link-keyvault-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}