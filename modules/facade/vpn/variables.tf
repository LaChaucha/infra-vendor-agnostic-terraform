variable "vendor" {
  type        = string
  description = "Cloud vendor implementation to use (e.g., aws)."
}

variable "enabled" {
  type    = bool
  default = true
}

variable "name" {
  type = string
}

# agnóstico: id de la red (vpc/vnet/etc.)
variable "network_id" {
  type    = string
  default = null
}

# opcional: si ya existe un gateway del lado cloud
variable "vpn_gateway_id" {
  type    = string
  default = null
}

# ASN del lado cloud (si aplica al vendor)
variable "local_asn" {
  type    = number
  default = null
}

# opcional: si ya existe un "peer/customer gateway"
variable "peer_gateway_id" {
  type    = string
  default = null
}

# IP pública del peer (on-prem firewall, etc.)
variable "peer_public_ip" {
  type    = string
  default = null
}

variable "peer_asn" {
  type    = number
  default = 65000
}

# routing_mode: "static" o "bgp" (en AWS se traduce a static_routes_only)
variable "routing_mode" {
  type    = string
  default = "static"

  validation {
    condition     = contains(["static", "bgp"], var.routing_mode)
    error_message = "routing_mode must be either \"static\" or \"bgp\"."
  }
}

# redes remotas (solo necesarias en modo static)
variable "remote_cidrs" {
  type    = list(string)
  default = []
}

# route tables donde propagar rutas del VPN gateway (si aplica)
variable "route_table_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

# opcional: output de config (puede ser sensible)
variable "output_peer_configuration" {
  type    = bool
  default = false
}