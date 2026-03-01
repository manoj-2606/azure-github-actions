output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}
output "nsg_ids" {
  value = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}
