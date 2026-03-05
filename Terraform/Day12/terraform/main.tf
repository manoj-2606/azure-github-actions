# ============================================================
# RESOURCE GROUP + NETWORKING MODULE
# ============================================================

module "networking" {
  source = "./modules/networking"

  resource_group_name      = var.resource_group_name
  location                 = var.location

  # Hub VNet
  hub_vnet_name            = var.hub_vnet_name
  hub_vnet_address_space   = var.hub_vnet_address_space
  hub_subnet_name          = var.hub_subnet_name
  hub_subnet_prefix        = var.hub_subnet_prefix

  # Spoke VNet
  spoke_vnet_name          = var.spoke_vnet_name
  spoke_vnet_address_space = var.spoke_vnet_address_space
  app_subnet_name          = var.app_subnet_name
  app_subnet_prefix        = var.app_subnet_prefix
  data_subnet_name         = var.data_subnet_name
  data_subnet_prefix       = var.data_subnet_prefix
  pe_subnet_name           = var.pe_subnet_name
  pe_subnet_prefix         = var.pe_subnet_prefix

  tags = var.tags
}

# ============================================================
# STORAGE MODULE
# ============================================================

module "storage" {
  source = "./modules/storage"

  resource_group_name  = module.networking.resource_group_name
  location             = var.location
  storage_account_name = var.storage_account_name
  account_tier         = var.storage_account_tier
  replication_type     = var.storage_replication_type
  tags                 = var.tags

  # Networking module must finish first before storage is created
  depends_on = [module.networking]
}

# ============================================================
# KEY VAULT MODULE
# ============================================================

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = module.networking.resource_group_name
  location            = var.location
  key_vault_name      = var.key_vault_name
  sku_name            = var.key_vault_sku
  tenant_id           = var.tenant_id
  tags                = var.tags

  depends_on = [module.networking]
}

# ============================================================
# PRIVATE ENDPOINTS MODULE
# Wires storage + keyvault IDs into private endpoints
# and links DNS zones to both Hub and Spoke VNets
# ============================================================

module "private_endpoints" {
  source = "./modules/private-endpoints"

  resource_group_name  = module.networking.resource_group_name
  location             = var.location

  # Subnet where private endpoints will live
  pe_subnet_id         = module.networking.pe_subnet_id

  # VNet IDs for DNS zone linking
  hub_vnet_id          = module.networking.hub_vnet_id
  spoke_vnet_id        = module.networking.spoke_vnet_id

  # Storage inputs — from storage module outputs
  storage_account_id   = module.storage.storage_account_id
  storage_account_name = module.storage.storage_account_name

  # Key Vault inputs — from keyvault module outputs
  key_vault_id         = module.keyvault.key_vault_id
  key_vault_name       = module.keyvault.key_vault_name

  tags = var.tags

  # Storage and Key Vault must exist before private endpoints are created
  depends_on = [module.storage, module.keyvault]
}