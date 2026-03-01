output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}
output "workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}
output "primary_shared_key" {
  value     = azurerm_log_analytics_workspace.law.primary_shared_key
  sensitive = true
}
