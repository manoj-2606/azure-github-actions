# ============================================================
# NETWORKING OUTPUTS
# ============================================================

output "resource_group_name" {
  description = "Resource group where all Day 12 resources live"
  value       = module.networking.resource_group_name
}

output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet resource ID"
  value       = module.networking.spoke_vnet_id
}

output "pe_subnet_id" {
  description = "Private endpoint subnet ID"
  value       = module.networking.pe_subnet_id
}

output "app_subnet_id" {
  description = "App subnet ID"
  value       = module.networking.app_subnet_id
}

# ============================================================
# STORAGE OUTPUTS
# ============================================================

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "storage_account_id" {
  description = "Storage account resource ID"
  value       = module.storage.storage_account_id
}

output "storage_primary_blob_endpoint" {
  description = "Storage blob endpoint — resolves only via private DNS inside VNet"
  value       = module.storage.primary_blob_endpoint
}

# ============================================================
# KEY VAULT OUTPUTS
# ============================================================

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.key_vault_name
}

output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  description = "Key Vault URI — resolves only via private DNS inside VNet"
  value       = module.keyvault.key_vault_uri
}

# ============================================================
# PRIVATE ENDPOINT OUTPUTS
# ============================================================

output "storage_private_ip" {
  description = "Private IP assigned to storage private endpoint — should be in 10.1.3.x range"
  value       = module.private_endpoints.storage_private_ip
}

output "keyvault_private_ip" {
  description = "Private IP assigned to Key Vault private endpoint — should be in 10.1.3.x range"
  value       = module.private_endpoints.keyvault_private_ip
}

output "storage_private_endpoint_id" {
  description = "Storage private endpoint resource ID"
  value       = module.private_endpoints.storage_private_endpoint_id
}

output "keyvault_private_endpoint_id" {
  description = "Key Vault private endpoint resource ID"
  value       = module.private_endpoints.keyvault_private_endpoint_id
}

output "storage_dns_zone_id" {
  description = "Storage Private DNS Zone ID"
  value       = module.private_endpoints.storage_dns_zone_id
}

output "keyvault_dns_zone_id" {
  description = "Key Vault Private DNS Zone ID"
  value       = module.private_endpoints.keyvault_dns_zone_id
}
# ```

# ---

# ## ✅ STEP 6 Complete — 2 files, copy-paste ready

# | File | Paste into |
# |---|---|
# | `main.tf` | `terraform/main.tf` |
# | `outputs.tf` | `terraform/outputs.tf` |

# **3 things to understand:**

# `depends_on` on every module — Terraform can sometimes try to create private endpoints before the storage account is fully ready. `depends_on` forces the correct creation order: networking → storage/keyvault → private endpoints.

# `module.networking.resource_group_name` — storage and keyvault modules don't create their own RG. They reuse the one created by the networking module. This keeps everything in one RG.

# `outputs.tf` at root level — after `terraform apply` runs in the pipeline, these values are printed. You can see the actual private IPs assigned (`10.1.3.x`) and verify everything landed correctly.

# ---
# ```
# Step 1 — Foundation files                              ✅
# Step 2 — providers.tf, backend.tf, variables.tf        ✅
# Step 3 — modules/networking                            ✅
# Step 4 — modules/storage + modules/keyvault            ✅
# Step 5 — modules/private-endpoints + DNS zones         ✅
# Step 6 — root main.tf + outputs.tf                     ✅
# Step 7 — Azure DevOps pipeline YAML files              ⬅ next