variable "rg_name" {}
variable "location" {}

variable "storage_accounts" {
  type = set(string)
}

variable "subnets" {
  type = map(string)
}
