variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space"
}

variable "aks_subnet_name" {
  type        = string
  description = "AKS subnet name"
}

variable "aks_subnet_cidr" {
  type        = string
  description = "AKS subnet CIDR"
}

variable "log_analytics_name" {
  type        = string
  description = "Log Analytics workspace name"
}

variable "log_retention_days" {
  type        = number
  description = "Log retention in days"
  default     = 30
}

variable "aks_cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "aks_dns_prefix" {
  type        = string
  description = "AKS DNS prefix"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version"
  default     = null
}

variable "node_count" {
  type        = number
  description = "Default node count"
  default     = 2
}

variable "enable_auto_scaling" {
  type        = bool
  description = "Enable cluster autoscaler for the system node pool"
  default     = true
}

variable "min_node_count" {
  type        = number
  description = "Minimum node count when autoscaling is enabled"
  default     = 2
}

variable "max_node_count" {
  type        = number
  description = "Maximum node count when autoscaling is enabled"
  default     = 5
}

variable "max_pods" {
  type        = number
  description = "Maximum pods per node for Azure CNI IP planning"
  default     = 30
}

variable "autoscaler_scan_interval" {
  type        = string
  description = "How often autoscaler checks for scale actions"
  default     = "10s"
}

variable "autoscaler_scale_down_unneeded" {
  type        = string
  description = "How long nodes should be unneeded before scale down"
  default     = "10m"
}

variable "autoscaler_scale_down_utilization_threshold" {
  type        = string
  description = "Node utilization threshold for scale down"
  default     = "0.5"
}

variable "vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_DS2_v2"
}
