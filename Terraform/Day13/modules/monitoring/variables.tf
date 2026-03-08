variable "prefix" {
  description = "Naming prefix"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault"
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the Storage Account"
  type        = string
}

variable "nsg_id" {
  description = "Resource ID of the NSG"
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the VNet"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for activity logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}