resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-landingzone"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
