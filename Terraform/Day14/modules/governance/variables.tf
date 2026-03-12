variable "prefix" {
  description = "Naming prefix"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the resource group to assign policies to"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
}

variable "required_tags" {
  description = "Tag keys that must exist on all resources"
  type        = list(string)
}