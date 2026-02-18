variable "cluster_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_count" {
  type    = number
  default = 2
}

variable "enable_auto_scaling" {
  type    = bool
  default = true
}

variable "min_node_count" {
  type    = number
  default = 2
}

variable "max_node_count" {
  type    = number
  default = 5
}

variable "max_pods" {
  type    = number
  default = 30
}

variable "autoscaler_scan_interval" {
  type    = string
  default = "10s"
}

variable "autoscaler_scale_down_unneeded" {
  type    = string
  default = "10m"
}

variable "autoscaler_scale_down_utilization_threshold" {
  type    = string
  default = "0.5"
}

variable "vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
