resource "azurerm_resource_group" "hub_rg" {
  name     = "rg-hub-network"
  location = var.location
}

resource "azurerm_resource_group" "dev_rg" {
  name     = "rg-dev-network"
  location = var.location
}

resource "azurerm_resource_group" "prod_rg" {
  name     = "rg-prod-network"
  location = var.location
}
