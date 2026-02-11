provider "azurerm" {
  features {}
}

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-demo-test"
  location = "centralindia"
}
