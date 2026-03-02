# ============================================================
# The role_assignments map is the heart of this module.
#
# Each entry in the map = one role assignment
# Key   = a unique label (used internally by Terraform state)
# Value = the 3 things Azure needs to assign a role:
#           WHO  (principal_id)
#           WHAT (role_definition_name)
#           WHERE (scope)
# ============================================================

variable "role_assignments" {
  description = "Map of role assignments to create"
  type = map(object({
    principal_id         = string
    role_definition_name = string
    scope                = string
  }))

  # Example of what callers pass in:
  # role_assignments = {
  #   "storage_blob_contributor" = {
  #     principal_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  #     role_definition_name = "Storage Blob Data Contributor"
  #     scope                = "/subscriptions/.../resourceGroups/.../storageAccounts/..."
  #   }
  #   "rg_reader" = {
  #     principal_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  #     role_definition_name = "Reader"
  #     scope                = "/subscriptions/.../resourceGroups/rg-day11-identity"
  #   }
  # }
}
