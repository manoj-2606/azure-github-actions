provider "azurerm" {
  features {}

  subscription_id = "4985f681-bfb3-4e92-a131-b1e85dd4f934"
}
module "rg" {
  source   = "./modules/resource-group"
  name     = var.rg_name
  location = var.location
}

module "network" {
  source        = "./modules/network"
  vnet_name     = "demo-vnet"
  address_space = "10.0.0.0/16"
  subnets = {
    web = "10.0.1.0/24"
    db  = "10.0.2.0/24"
  }
}
