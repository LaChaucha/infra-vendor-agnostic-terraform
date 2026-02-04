variable "aws_region" { type = string }

variable "onprem_public_ip" {
  type        = string
  description = "Public IP of the on-prem VPN device / firewall."
}

variable "enable_vpn" {
  type    = bool
  default = true
}

variable "azs_override" {
  type    = list(string)
  default = []
}