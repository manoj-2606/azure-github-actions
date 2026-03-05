output "storage_private_endpoint_id" {
  description = "Storage private endpoint resource ID"
  value       = azurerm_private_endpoint.storage.id
}

output "storage_private_ip" {
  description = "Private IP assigned to the storage private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "keyvault_private_endpoint_id" {
  description = "Key Vault private endpoint resource ID"
  value       = azurerm_private_endpoint.keyvault.id
}

output "keyvault_private_ip" {
  description = "Private IP assigned to the Key Vault private endpoint"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}

output "storage_dns_zone_id" {
  description = "Storage Private DNS Zone ID"
  value       = azurerm_private_dns_zone.storage.id
}

output "keyvault_dns_zone_id" {
  description = "Key Vault Private DNS Zone ID"
  value       = azurerm_private_dns_zone.keyvault.id
}
# ```

# ---

# ## ✅ STEP 5 Complete — 3 files, copy-paste ready

# | File | Paste into |
# |---|---|
# | `variables.tf` | `modules/private-endpoints/variables.tf` |
# | `main.tf` | `modules/private-endpoints/main.tf` |
# | `outputs.tf` | `modules/private-endpoints/outputs.tf` |

# **3 things to understand before moving on:**

# `private_dns_zone_group` block inside the private endpoint — this is what tells Azure to **automatically create the A record** in your DNS zone pointing to the private IP. Without this block you'd have to create the DNS A record manually.

# `registration_enabled = false` on DNS zone links — this means the VNet won't auto-register its VM hostnames into this DNS zone. You only want storage/keyvault records in here, not every VM in the VNet.

# `subresource_names = ["blob"]` for storage and `["vault"]` for Key Vault — these are fixed strings defined by Microsoft. Getting them wrong means the private endpoint connects to the wrong service. Blob = blob storage, vault = Key Vault.

# ---
# ```
# Step 1 — Foundation files                              ✅
# Step 2 — providers.tf, backend.tf, variables.tf        ✅
# Step 3 — modules/networking                            ✅
# Step 4 — modules/storage + modules/keyvault            ✅
# Step 5 — modules/private-endpoints + DNS zones         ✅
# Step 6 — root main.tf + outputs.tf                     ⬅ next
# Step 7 — Azure DevOps pipeline YAML files