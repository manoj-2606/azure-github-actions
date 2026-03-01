terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stgtfstate2606"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}
