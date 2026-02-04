module "aws_vpn" {
  count  = (var.enabled && var.vendor == "aws") ? 1 : 0
  source = "../../aws/vpn"

  enabled = var.enabled
  name    = var.name

  vpc_id         = var.network_id
  vpn_gateway_id = var.vpn_gateway_id
  amazon_side_asn = var.local_asn

  customer_gateway_id  = var.peer_gateway_id
  customer_gateway_ip  = var.peer_public_ip
  customer_gateway_asn = var.peer_asn

  static_routes_only = (var.routing_mode == "static")
  remote_cidrs       = var.remote_cidrs

  route_table_ids = var.route_table_ids

  tags = var.tags

  output_customer_gateway_configuration = var.output_peer_configuration
}