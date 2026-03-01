##
provider "azurerm" {
  features {}
  subscription_id = "4985f681-bfb3-4e92-a131-b1e85dd4f934"
}

module "rg" {
  source   = "../../modules/rg"
  name     = "rg-stage-demo"
  location = "centralindia"
}
