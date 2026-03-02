# principal_id → passed to RBAC module for role assignments
# client_id    → used by app code to authenticate to Azure APIs
# id           → used to attach this identity to a VM / App Service

output "principal_id" {
  description = "Object ID of the managed identity — pass this to RBAC module"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID — used for SDK/API auth from app code"
  value       = azurerm_user_assigned_identity.this.client_id
}

output "id" {
  description = "Full resource ID — used to attach identity to VMs, App Services"
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the managed identity"
  value       = azurerm_user_assigned_identity.this.name
}
