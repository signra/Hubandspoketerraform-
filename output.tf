output "hub_vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "firewall_public_ip" {
  value = azurerm_public_ip.firewall_pip.ip_address
}
