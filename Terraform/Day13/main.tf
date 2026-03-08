data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "main" {
  name                       = "${var.prefix}-kv-monitoring"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = {
    environment = "day13"
    purpose     = "monitoring-lab"
  }
}

resource "azurerm_storage_account" "main" {
  name                     = "${var.prefix}stmonitoring"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = {
    environment = "day13"
    purpose     = "monitoring-lab"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "day13"
    purpose     = "monitoring-lab"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "day13"
    purpose     = "monitoring-lab"
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  prefix              = var.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subscription_id     = var.subscription_id

  key_vault_id       = azurerm_key_vault.main.id
  storage_account_id = azurerm_storage_account.main.id
  nsg_id             = azurerm_network_security_group.main.id
  vnet_id            = azurerm_virtual_network.main.id

  tags = {
    environment = "day13"
    purpose     = "monitoring-lab"
  }
}