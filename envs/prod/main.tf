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
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    project     = "infra-vendor-agnostic-terraform"
    environment = "prod"
  }
}

module "network" {
  source = "../../modules/facade/network"

  vendor   = "aws"
  name     = "prod"
  vpc_cidr = "10.10.0.0/16"

  private_subnets = [
    { name = "prod-private-a", cidr = "10.10.10.0/24", az = local.azs[0] },
    { name = "prod-private-b", cidr = "10.10.20.0/24", az = local.azs[1] },
  ]

  tags = local.tags
}

module "vpn" {
  source = "../../modules/facade/vpn"

  vendor     = "aws"
  enabled    = true
  name       = "prod"
  network_id = module.network.network_id

  peer_public_ip = var.onprem_public_ip
  peer_asn       = 65000

  routing_mode = "static"
  remote_cidrs  = ["192.168.0.0/16"]

  route_table_ids = [module.network.private_route_table_id]

  tags = local.tags
}

output "prod_vpc_id" {
  value = module.network.network_id
}

output "prod_vpn_tunnels" {
  value = module.vpn.tunnel_endpoints
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.azs_override) > 0
    ? var.azs_override
    : slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    project     = "infra-vendor-agnostic-terraform"
    environment = "prod"
  }
}

# ...
module "vpn" {
  source  = "../../modules/facade/vpn"
  vendor  = "aws"
  enabled = var.enable_vpn
  # ...
}