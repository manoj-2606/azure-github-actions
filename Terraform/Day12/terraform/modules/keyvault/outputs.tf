output "key_vault_id" {
  description = "Key Vault resource ID — used by private endpoint module"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI (will only resolve via private DNS)"
  value       = azurerm_key_vault.main.vault_uri
}
# ```

# ---

# ## ✅ STEP 4 Complete — 6 files, copy-paste ready

# | File | Paste into |
# |---|---|
# | Storage `variables.tf` | `modules/storage/variables.tf` |
# | Storage `main.tf` | `modules/storage/main.tf` |
# | Storage `outputs.tf` | `modules/storage/outputs.tf` |
# | Key Vault `variables.tf` | `modules/keyvault/variables.tf` |
# | Key Vault `main.tf` | `modules/keyvault/main.tf` |
# | Key Vault `outputs.tf` | `modules/keyvault/outputs.tf` |

# **Two things to understand before moving on:**

# `public_network_access_enabled = false` + `network_rules default_action = "Deny"` — these two together are what fully blocks public access. One alone is not enough.

# `data "azurerm_client_config" "current"` in Key Vault — this fetches the identity of whoever is running Terraform (your pipeline SP) and gives it access policy automatically. Without this, even Terraform itself can't write secrets after creating the vault.

# ---
# ```
# Step 1 — Foundation files                              ✅
# Step 2 — providers.tf, backend.tf, variables.tf        ✅
# Step 3 — modules/networking                            ✅
# Step 4 — modules/storage + modules/keyvault            ✅
# Step 5 — modules/private-endpoints + DNS zones         ⬅ next
# Step 6 — root main.tf + outputs.tf
# Step 7 — Azure DevOps pipeline YAML files