terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.azs_override) > 0 ? var.azs_override : slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    project     = "infra-vendor-agnostic-terraform"
    environment = "nonprod"
  }
}

module "network" {
  source = "../../modules/facade/network"

  vendor   = "aws"
  name     = "nonprod"
  vpc_cidr = "10.20.0.0/16"

  private_subnets = [
    { name = "nonprod-dev-a", cidr = "10.20.10.0/24", az = local.azs[0] },
    { name = "nonprod-dev-b", cidr = "10.20.20.0/24", az = local.azs[1] },
    { name = "nonprod-qa-a",  cidr = "10.20.30.0/24", az = local.azs[0] },
    { name = "nonprod-qa-b",  cidr = "10.20.40.0/24", az = local.azs[1] },
  ]

  tags = local.tags
}

module "vpn" {
  source = "../../modules/facade/vpn"

  vendor     = "aws"
  enabled    = var.enable_vpn
  name       = "nonprod"
  network_id = module.network.network_id

  peer_public_ip = var.onprem_public_ip
  peer_asn       = 65000

  routing_mode = "static"
  remote_cidrs  = ["192.168.0.0/16"]

  route_table_ids = [module.network.private_route_table_id]

  tags = local.tags
}

output "nonprod_vpc_id" {
  value = module.network.network_id
}

output "nonprod_vpn_tunnels" {
  value = module.vpn.tunnel_endpoints
}
