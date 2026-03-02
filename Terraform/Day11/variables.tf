variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Main resource group for Day 11 resources"
  type        = string
  default     = "rg-day11-identity"
}

variable "project_name" {
  description = "Short project identifier used in resource naming"
  type        = string
  default     = "day11"
}

variable "environment" {
  description = "Environment tag (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "storage_account_name" {
  description = "Name for the app storage account (used for RBAC exercise)"
  type        = string
}

variable "key_vault_name" {
  description = "Name for the Key Vault (must be globally unique, 3-24 chars)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    project     = "day11"
    environment = "dev"
    managed_by  = "terraform"
    day         = "11"
  }
}
