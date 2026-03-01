provider "azurerm" {
  features {}

  subscription_id = "4985f681-bfb3-4e92-a131-b1e85dd4f934"
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = "centralindia"
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "stgtfstate2606"
  resource_group_name             = "rg-tfstate"
  location                        = "centralindia"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_0"

  lifecycle {
    prevent_destroy = true
  }

}
