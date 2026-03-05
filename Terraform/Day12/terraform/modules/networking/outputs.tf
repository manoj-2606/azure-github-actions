output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_id" {
  description = "Spoke VNet resource ID"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Spoke VNet name"
  value       = azurerm_virtual_network.spoke.name
}

output "app_subnet_id" {
  description = "App subnet resource ID"
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  description = "Data subnet resource ID"
  value       = azurerm_subnet.data.id
}

output "pe_subnet_id" {
  description = "Private endpoint subnet resource ID — used by private endpoint module"
  value       = azurerm_subnet.pe.id
}
# ```

# ---

# ## ✅ STEP 3 Complete

# 3 files for `modules/networking/`. Here's what to understand before moving on:

# **Why `private_endpoint_network_policies_enabled = false` on pe-subnet?** — Azure requires this to be disabled on any subnet where private endpoints are placed. Without it, the private endpoint NIC cannot be assigned an IP.

# **Why peering in both directions?** — Azure VNet peering is not transitive. `hub→spoke` only allows hub to see spoke. You must also create `spoke→hub` for spoke resources to reach hub. Both must show `"Connected"` state.

# **Why two NSGs?** — The app-subnet NSG controls what hits your app. The pe-subnet NSG ensures only your app-subnet (and hub) can reach the private endpoints — not random internet traffic.

# ---
# ```
# Step 1 — Foundation files                              ✅
# Step 2 — providers.tf, backend.tf, variables.tf        ✅
# Step 3 — modules/networking                            ✅
# Step 4 — modules/storage + modules/keyvault            ⬅ next
# Step 5 — modules/private-endpoints + DNS zones
# Step 6 — root main.tf + outputs.tf
# Step 7 — Azure DevOps pipeline YAML files
