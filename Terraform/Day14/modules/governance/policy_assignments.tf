resource "azurerm_policy_assignment" "governance_baseline" {
  name                 = "${var.prefix}-governance-assignment"
  display_name         = "Day14 - Governance Baseline Assignment"
  description          = "Assigns the governance baseline initiative to the Day14 resource group"
  policy_definition_id = azurerm_policy_set_definition.governance_baseline.id

  # Scope: resource group — only resources inside this RG are evaluated
  # To enforce subscription-wide: replace with /subscriptions/${var.subscription_id}
  scope = var.resource_group_id

  parameters = jsonencode({
    allowedLocations = {
      value = var.allowed_locations
    }
  })

  # Identity needed for DeployIfNotExists and Modify effects
  # Not strictly required for Deny/Audit but good practice to include
  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# Grant the policy assignment's managed identity the role it needs
# Required when using DeployIfNotExists or Modify effects
# Kept here as preparation for production escalation
resource "azurerm_role_assignment" "policy_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_policy_assignment.governance_baseline.identity[0].principal_id
}