output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "vnet_name" {
  value = module.networking.vnet_name
}
output "subnet_ids" {
  value = module.networking.subnet_ids
}
output "storage_account_name" {
  value = module.storage.storage_account_name
}
output "key_vault_name" {
  value = module.keyvault.key_vault_name
}
output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}
output "log_analytics_workspace_id" {
  value = module.monitoring.workspace_id
}
