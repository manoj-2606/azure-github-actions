output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "storage_account_id" {
  description = "Storage Account resource ID"
  value       = azurerm_storage_account.main.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.monitoring.workspace_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  value       = module.monitoring.workspace_name
}