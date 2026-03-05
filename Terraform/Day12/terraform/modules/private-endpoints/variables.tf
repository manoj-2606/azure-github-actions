variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "pe_subnet_id" {
  description = "Subnet ID where private endpoints will be placed (pe-subnet)"
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID — DNS zone will be linked to this VNet"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID — DNS zone will be linked to this VNet"
  type        = string
}

variable "storage_account_id" {
  description = "Storage account resource ID — from storage module output"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name — used to name the private endpoint"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID — from keyvault module output"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name — used to name the private endpoint"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}