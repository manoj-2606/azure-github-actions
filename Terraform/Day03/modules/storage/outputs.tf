output "names" {
  value = keys(azurerm_storage_account.sa)
}
