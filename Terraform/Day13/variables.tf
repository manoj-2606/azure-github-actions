variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "prefix" {
  description = "Naming prefix for all resources"
  type        = string
  default     = "day13"
}

variable "subscription_id" {
  description = "Azure subscription ID for activity logs"
  type        = string
}