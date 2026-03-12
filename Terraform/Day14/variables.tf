variable "resource_group_name" {
  description = "Name of the resource group for governance resources"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "centralindia"
}

variable "prefix" {
  description = "Naming prefix"
  type        = string
  default     = "day14"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["centralindia", "westeurope"]
}

variable "required_tags" {
  description = "List of tag keys that must exist on all resources"
  type        = list(string)
  default     = ["environment", "owner", "costCenter"]
}