output "storage_account_id" {
  description = "Storage account resource ID — used by private endpoint module"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint (will only resolve via private DNS)"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}