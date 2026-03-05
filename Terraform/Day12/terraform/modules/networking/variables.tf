variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Hub VNet address space"
  type        = list(string)
}

variable "hub_subnet_name" {
  description = "Subnet name inside Hub VNet"
  type        = string
}

variable "hub_subnet_prefix" {
  description = "Hub subnet CIDR"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Spoke VNet name"
  type        = string
}

variable "spoke_vnet_address_space" {
  description = "Spoke VNet address space"
  type        = list(string)
}

variable "app_subnet_name" {
  description = "App subnet name in Spoke VNet"
  type        = string
}

variable "app_subnet_prefix" {
  description = "App subnet CIDR"
  type        = string
}

variable "data_subnet_name" {
  description = "Data subnet name in Spoke VNet"
  type        = string
}

variable "data_subnet_prefix" {
  description = "Data subnet CIDR"
  type        = string
}

variable "pe_subnet_name" {
  description = "Private endpoint subnet name in Spoke VNet"
  type        = string
}

variable "pe_subnet_prefix" {
  description = "Private endpoint subnet CIDR"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
