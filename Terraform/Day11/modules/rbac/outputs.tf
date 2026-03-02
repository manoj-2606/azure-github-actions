# ============================================================
# Outputs the full map of created role assignment IDs
# Useful for debugging and audit — you can see exactly
# which role assignments Terraform created and their IDs
# ============================================================

output "role_assignment_ids" {
  description = "Map of role assignment resource IDs keyed by assignment label"
  value = {
    for k, v in azurerm_role_assignment.this : k => v.id
  }
}

output "role_assignment_summary" {
  description = "Human-readable summary of what was assigned where"
  value = {
    for k, v in azurerm_role_assignment.this : k => {
      role  = v.role_definition_name
      scope = v.scope
    }
  }
}
