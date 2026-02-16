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

variable "environment" {
  description = "Deployment environment name (e.g. dev, test, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "enable_monitoring" {
  description = "Enable Log Analytics Workspace (should typically be true only for prod)"
  type        = bool
  default     = false
}
