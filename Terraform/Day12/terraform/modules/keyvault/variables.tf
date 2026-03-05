variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name (globally unique, 3-24 chars)"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "tenant_id" {
  description = "Azure AD tenant ID — required by Key Vault"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}