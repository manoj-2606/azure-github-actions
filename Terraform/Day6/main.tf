provider "azurerm" {
  features {}

  subscription_id = "4985f681-bfb3-4e92-a131-b1e85dd4f934"
}

data "azurerm_resource_group" "tfstate_rg" {
  name = "rg-tfstate"
}
data "azurerm_storage_account" "tfstate_sa" {
  name                = "stgtfstate2606"
  resource_group_name = "rg-tfstate"
}
