resource "azurerm_resource_group_policy_assignment" "governance_baseline" {
  name                 = "${var.prefix}-governance-assignment"
  display_name         = "Day14 - Governance Baseline Assignment"
  description          = "Assigns the governance baseline initiative to the Day14 resource group"
  policy_definition_id = azurerm_policy_set_definition.governance_baseline.id
  resource_group_id    = var.resource_group_id

  parameters = jsonencode({
    allowedLocations = {
      value = var.allowed_locations
    }
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

resource "azurerm_role_assignment" "policy_contributor" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_resource_group_policy_assignment.governance_baseline.identity[0].principal_id
}