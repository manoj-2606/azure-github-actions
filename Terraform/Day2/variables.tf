# Stop hardcoding values. Everything dynamic.

variable "location" {
  default = "centralindia"
}

variable "storage_names" {
  type = set(string)
}

variable "subnets" {
  type = map(string)
}
