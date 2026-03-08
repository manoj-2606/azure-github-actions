resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "${var.prefix}-diag-nsg"
  target_resource_id         = var.nsg_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "${var.prefix}-diag-vnet"
  target_resource_id         = var.vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}