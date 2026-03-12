output "policy_initiative_id" {
  description = "Policy initiative ID"
  value       = azurerm_policy_set_definition.governance_baseline.id
}

output "policy_assignment_id" {
  description = "Policy assignment ID"
  value       = azurerm_resource_group_policy_assignment.governance_baseline.id
}