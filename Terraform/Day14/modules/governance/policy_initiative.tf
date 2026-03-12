resource "azurerm_policy_set_definition" "governance_baseline" {
  name         = "${var.prefix}-governance-baseline"
  policy_type  = "Custom"
  display_name = "Day14 - Governance Baseline Initiative"
  description  = "Bundles all Day14 governance policies into one assignable initiative"

  metadata = jsonencode({
    category = "General"
    version  = "1.0.0"
  })

  # Parameter exposed at initiative level — passed down to the definition
  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "Regions permitted for resource deployment"
      }
    }
  })

  # Policy 1 — Allowed Locations
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
    parameter_values = jsonencode({
      allowedLocations = {
        value = "[parameters('allowedLocations')]"
      }
    })
  }

  # Policy 2a — Require environment tag
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_environment_tag.id
  }

  # Policy 2b — Require owner tag
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_owner_tag.id
  }

  # Policy 2c — Require costCenter tag
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_costcenter_tag.id
  }

  # Policy 3 — Deny public storage
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_storage.id
  }

  # Policy 4 — Audit diagnostic settings
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.audit_diagnostic_settings.id
  }
}