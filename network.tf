resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub"
  address_space       = [var.hub_vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name
}
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_virtual_network" "dev_vnet" {
  name                = "vnet-dev"
  address_space       = [var.dev_vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.dev_rg.name
}
resource "azurerm_virtual_network" "prod_vnet" {
  name                = "vnet-prod"
  address_space       = [var.prod_vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.prod_rg.name
}
resource "azurerm_virtual_network_peering" "dev_to_hub" {
  name                      = "dev-to-hub"
  resource_group_name       = azurerm_resource_group.dev_rg.name
  virtual_network_name      = azurerm_virtual_network.dev_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}
resource "azurerm_virtual_network_peering" "hub_to_dev" {
  name                      = "hub_to_dev"
  resource_group_name       = azurerm_resource_group.dev_rg.name
  virtual_network_name      = azurerm_virtual_network.dev_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}
resource "azurerm_virtual_network_peering" "prod_to_hub" {
  name                      = "prod_to_hub"
  resource_group_name       = azurerm_resource_group.dev_rg.name
  virtual_network_name      = azurerm_virtual_network.dev_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}
resource "azurerm_virtual_network_peering" "hub_to_prod" {
  name                      = "hub_to_prod"
  resource_group_name       = azurerm_resource_group.dev_rg.name
  virtual_network_name      = azurerm_virtual_network.dev_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}
