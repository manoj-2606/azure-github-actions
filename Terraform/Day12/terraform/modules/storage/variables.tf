variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name (globally unique, lowercase, max 24 chars)"
  type        = string
}

variable "account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}