terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatehubspoke01"
    container_name       = "tfstate"
    key                  = "aks-platform-prod.tfstate"
  }
}
