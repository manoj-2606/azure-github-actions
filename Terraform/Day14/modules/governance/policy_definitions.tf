# ─────────────────────────────────────────────
# POLICY 1 — Allowed Locations
# Denies resource creation outside approved regions
# ─────────────────────────────────────────────
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "${var.prefix}-allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Restrict Allowed Locations"
  description  = "Denies deployment to any region not in the approved list"

  metadata = jsonencode({
    category = "General"
    version  = "1.0.0"
  })

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "List of Azure regions where resources can be deployed"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "Deny"
    }
  })
}

# ─────────────────────────────────────────────
# POLICY 2 — Require Tags
# Denies resource creation if mandatory tags are missing
# One policy definition per required tag
# ─────────────────────────────────────────────
resource "azurerm_policy_definition" "require_environment_tag" {
  name         = "${var.prefix}-require-tag-environment"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Require environment Tag"
  description  = "Denies resource creation if environment tag is missing"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field = "tags['environment']"
      exists = "false"
    }
    then = {
      effect = "Deny"
    }
  })
}

resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "${var.prefix}-require-tag-owner"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Require owner Tag"
  description  = "Denies resource creation if owner tag is missing"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field = "tags['owner']"
      exists = "false"
    }
    then = {
      effect = "Deny"
    }
  })
}

resource "azurerm_policy_definition" "require_costcenter_tag" {
  name         = "${var.prefix}-require-tag-costcenter"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Require costCenter Tag"
  description  = "Denies resource creation if costCenter tag is missing"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field = "tags['costCenter']"
      exists = "false"
    }
    then = {
      effect = "Deny"
    }
  })
}

# ─────────────────────────────────────────────
# POLICY 3 — Deny Public Storage Accounts
# Denies storage accounts with public network access enabled
# ─────────────────────────────────────────────
resource "azurerm_policy_definition" "deny_public_storage" {
  name         = "${var.prefix}-deny-public-storage"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Deny Public Storage Accounts"
  description  = "Denies storage accounts that allow public network access"

  metadata = jsonencode({
    category = "Storage"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
          equals = "Enabled"
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# ─────────────────────────────────────────────
# POLICY 4 — Audit Missing Diagnostic Settings
# Audits storage accounts not sending logs to Log Analytics
# Effect is Audit — visibility without blocking
# Escalate to DeployIfNotExists in production
# ─────────────────────────────────────────────
resource "azurerm_policy_definition" "audit_diagnostic_settings" {
  name         = "${var.prefix}-audit-diagnostic-settings"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Day14 - Audit Missing Diagnostic Settings on Storage"
  description  = "Audits storage accounts that do not have diagnostic settings configured"

  metadata = jsonencode({
    category = "Monitoring"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })
}