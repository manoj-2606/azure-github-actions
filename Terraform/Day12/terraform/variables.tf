# ============================================================
# AUTHENTICATION — injected by pipeline via variable group
# ============================================================

variable "client_id" {
  description = "Azure Service Principal client ID (OIDC)"
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# ============================================================
# PROJECT SETTINGS
# ============================================================

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Name of the main resource group for Day 12"
  type        = string
  default     = "rg-day12-centralindia"
}

variable "project" {
  description = "Short project tag applied to all resources"
  type        = string
  default     = "day12"
}

variable "environment" {
  description = "Environment tag (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ============================================================
# NETWORKING — Hub VNet
# ============================================================

variable "hub_vnet_name" {
  description = "Name of the Hub VNet"
  type        = string
  default     = "hub-vnet"
}

variable "hub_vnet_address_space" {
  description = "Address space for the Hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "hub_subnet_name" {
  description = "Name of the general subnet inside Hub VNet"
  type        = string
  default     = "hub-subnet"
}

variable "hub_subnet_prefix" {
  description = "CIDR prefix for hub-subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# ============================================================
# NETWORKING — Spoke VNet
# ============================================================

variable "spoke_vnet_name" {
  description = "Name of the Spoke VNet"
  type        = string
  default     = "spoke-vnet"
}

variable "spoke_vnet_address_space" {
  description = "Address space for the Spoke VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "app_subnet_name" {
  description = "Application workload subnet in Spoke VNet"
  type        = string
  default     = "app-subnet"
}

variable "app_subnet_prefix" {
  description = "CIDR prefix for app-subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "data_subnet_name" {
  description = "Data tier subnet in Spoke VNet"
  type        = string
  default     = "data-subnet"
}

variable "data_subnet_prefix" {
  description = "CIDR prefix for data-subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "pe_subnet_name" {
  description = "Private endpoint subnet in Spoke VNet"
  type        = string
  default     = "pe-subnet"
}

variable "pe_subnet_prefix" {
  description = "CIDR prefix for pe-subnet (private endpoints live here)"
  type        = string
  default     = "10.1.3.0/24"
}

# ============================================================
# STORAGE ACCOUNT
# ============================================================

variable "storage_account_name" {
  description = "Name of the Storage Account (globally unique, lowercase, max 24 chars)"
  type        = string
  default     = "stday12ci001"
}

variable "storage_account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

# ============================================================
# KEY VAULT
# ============================================================

variable "key_vault_name" {
  description = "Name of the Key Vault (globally unique, 3-24 chars)"
  type        = string
  default     = "kv-day12-ci-001"
}

variable "key_vault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

# ============================================================
# TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project     = "day12"
    environment = "dev"
    managed_by  = "terraform"
    day         = "day12-secure-network"
  }
}
