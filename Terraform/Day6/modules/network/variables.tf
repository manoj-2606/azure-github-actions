variable "name_prefix" {
  description = "Prefix used for naming all network resources"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where network resources will be created"
  type        = string
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number

  validation {
    condition     = var.subnet_count > 0 && var.subnet_count <= 250
    error_message = "subnet_count must be between 1 and 250."
  }
}
