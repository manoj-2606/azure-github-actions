# ============================================================
# Key Vault Outputs
#
# id  → passed as scope to RBAC module for secret access roles
# uri → used by app code / pipelines to read secrets
# ============================================================

output "id" {
  description = "Resource ID of the Key Vault — use as scope in RBAC module"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "Vault URI — used by apps to connect and read secrets"
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Tenant ID the Key Vault belongs to"
  value       = azurerm_key_vault.this.tenant_id
}
