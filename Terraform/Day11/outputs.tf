# ============================================================
# Root Outputs
# These print after terraform apply — useful for verification
# and for passing values to other pipelines or workspaces
# ============================================================

output "identity_principal_id" {
  description = "Principal ID of the managed identity (used in RBAC)"
  value       = module.identity.principal_id
}

output "identity_client_id" {
  description = "Client ID of the managed identity (used by app code)"
  value       = module.identity.client_id
}

output "identity_id" {
  description = "Full resource ID of the managed identity"
  value       = module.identity.id
}

output "storage_account_id" {
  description = "Resource ID of the app storage account"
  value       = azurerm_storage_account.app.id
}

output "storage_account_name" {
  description = "Name of the app storage account"
  value       = azurerm_storage_account.app.name
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = module.keyvault.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault — used by apps to fetch secrets"
  value       = module.keyvault.uri
}

output "role_assignments" {
  description = "Summary of all role assignments created"
  value       = module.rbac.role_assignment_summary
}
# ```

# ---

# ## 📁 Final File Placement Check
# ```
# day11/
# ├── main.tf           ← NEW this step
# ├── outputs.tf        ← NEW this step
# ├── providers.tf      ← done (Step 2)
# ├── variables.tf      ← done (Step 2)
# ├── terraform.tfvars  ← done (Step 2)
# └── modules/
#     ├── identity/     ← done (Step 2)
#     ├── rbac/         ← done (Step 3)
#     └── keyvault/     ← done (Step 4)
# ```

# ---

# ## 💡 How the 3 Modules Connect — Data Flow
# ```
# module.identity
#   └── outputs principal_id
#             │
#             ▼
# module.rbac  ← also takes module.keyvault.id as scope
#   └── creates 3 role assignments via for_each
#             │
#             ▼
#   storage_blob_contributor  → scoped to storage account
#   rg_reader                 → scoped to resource group
#   kv_secrets_user           → scoped to key vault

# module.keyvault
#   └── outputs id (used as scope above)