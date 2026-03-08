output "workspace_id" {
  description = "Log Analytics Workspace resource ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_customer_id" {
  description = "Log Analytics Workspace customer/tenant ID used for queries"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}