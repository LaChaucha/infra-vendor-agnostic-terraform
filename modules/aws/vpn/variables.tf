variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "vpn_gateway_id" {
  type    = string
  default = null
}

variable "amazon_side_asn" {
  type    = number
  default = null
}

variable "customer_gateway_id" {
  type    = string
  default = null
}

variable "customer_gateway_ip" {
  type    = string
  default = null
}

variable "customer_gateway_asn" {
  type    = number
  default = 65000
}

variable "static_routes_only" {
  type    = bool
  default = true
}

variable "remote_cidrs" {
  type    = list(string)
  default = []
}

variable "route_table_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "output_customer_gateway_configuration" {
  type    = bool
  default = false
}