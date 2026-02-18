terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  tags = {
    environment = "dev"
    workload    = "aks-platform"
  }
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "networking" {
  source              = "../../modules/networking"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  aks_subnet_name     = var.aks_subnet_name
  aks_subnet_cidr     = var.aks_subnet_cidr
  tags                = local.tags
}

module "log_analytics" {
  source              = "../../modules/log-analytics"
  name                = var.log_analytics_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = var.aks_cluster_name
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = var.aks_dns_prefix
  kubernetes_version         = var.kubernetes_version
  node_count                 = var.node_count
  enable_auto_scaling        = var.enable_auto_scaling
  min_node_count             = var.min_node_count
  max_node_count             = var.max_node_count
  max_pods                   = var.max_pods
  autoscaler_scan_interval   = var.autoscaler_scan_interval
  autoscaler_scale_down_unneeded = var.autoscaler_scale_down_unneeded
  autoscaler_scale_down_utilization_threshold = var.autoscaler_scale_down_utilization_threshold
  vm_size                    = var.vm_size
  subnet_id                  = module.networking.aks_subnet_id
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.tags
}
