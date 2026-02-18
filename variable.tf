variable "location" {
  default = "UK South"
}

variable "hub_vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "dev_vnet_cidr" {
  default = "10.1.0.0/16"
}

variable "prod_vnet_cidr" {
  default = "10.2.0.0/16"
}
