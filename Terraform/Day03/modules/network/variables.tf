variable "vnet_name" {}
variable "address_space" {}
variable "subnets" { type = map(string) }
variable "rg_name" {}
variable "location" {}
