variable "location" {}
variable "rg_name" {}
variable "storage_name" {}
variable "vnet_name" {}
variable "subnet_name" {}

variable "address_space" {
 type = list(string)
}

variable "subnet_prefix" {
 type = list(string)
}