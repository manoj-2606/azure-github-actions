variable "key_vault_name" {
  description = "Name of the Key Vault — must be globally unique, 3-24 chars"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Key Vault will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}