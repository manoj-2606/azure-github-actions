variable "identity_name" {
  description = "Name of the User-Assigned Managed Identity"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the identity will be created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the identity resource"
  type        = map(string)
  default     = {}
}
