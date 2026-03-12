data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "day14"
    owner       = "devops-learning"
    costCenter  = "training"
  }
}

module "governance" {
  source = "./modules/governance"

  prefix              = var.prefix
  resource_group_id   = azurerm_resource_group.main.id
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subscription_id     = var.subscription_id
  allowed_locations   = var.allowed_locations
  required_tags       = var.required_tags
}