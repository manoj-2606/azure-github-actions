resource "azurerm_storage_account" "sa" {
  for_each = toset(var.names)

  name                     = each.value
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
