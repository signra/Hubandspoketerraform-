resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name           = "system"
    vm_size        = var.vm_size
    node_count     = var.enable_auto_scaling ? null : var.node_count
    enable_auto_scaling = var.enable_auto_scaling
    min_count      = var.enable_auto_scaling ? var.min_node_count : null
    max_count      = var.enable_auto_scaling ? var.max_node_count : null
    max_pods       = var.max_pods
    vnet_subnet_id = var.subnet_id

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  auto_scaler_profile {
    scan_interval                    = var.autoscaler_scan_interval
    scale_down_unneeded              = var.autoscaler_scale_down_unneeded
    scale_down_utilization_threshold = var.autoscaler_scale_down_utilization_threshold
  }
}
