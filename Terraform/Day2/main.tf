terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "rg-demo-test"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "local.vnet_name"
  address_space       = ["10.0.0./16"]
  location            = data.azurerm_resource_group.rg.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Only one. No loop needed.

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# Understand what you just did:

# Terraform will create:

# subnets["app"]
# subnets["db"]
# subnets["web"]

# Stable. Predictable. Professional.

# If you used count here, that’s amateur.

resource "azurerm_storage_account" "stg" {
  for_each = var.storage_names

  name                     = each.value
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Now:

# Add name → new resource
# Remove name → only that one destroyed

# Zero blast radius.

# That’s the goal.
