variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }
variable "secrets" {
  type    = map(string)
  default = {}
  # sensitive removed from variable — values are protected inside Key Vault itself
}
