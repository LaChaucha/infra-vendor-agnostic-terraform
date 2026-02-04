module "aws_network" {
  count  = var.vendor == "aws" ? 1 : 0
  source = "../../aws/network"

  name            = var.name
  vpc_cidr         = var.vpc_cidr
  private_subnets  = var.private_subnets
  tags             = var.tags
}