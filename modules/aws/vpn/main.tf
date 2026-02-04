locals {
  create_vgw = var.vpn_gateway_id == null
  create_cgw = var.customer_gateway_id == null
}

resource "aws_vpn_gateway" "this" {
  count = (var.enabled && local.create_vgw) ? 1 : 0

  vpc_id          = var.vpc_id
  amazon_side_asn = var.amazon_side_asn

  tags = merge(var.tags, {
    Name = "${var.name}-vgw"
  })
}

resource "aws_customer_gateway" "this" {
  count = (var.enabled && local.create_cgw) ? 1 : 0

  bgp_asn    = var.customer_gateway_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.name}-cgw"
  })
}

locals {
  effective_vpn_gateway_id = var.vpn_gateway_id != null ? var.vpn_gateway_id : try(aws_vpn_gateway.this[0].id, null)
  effective_customer_gateway_id = var.customer_gateway_id != null ? var.customer_gateway_id : try(aws_customer_gateway.this[0].id, null)
}

resource "aws_vpn_connection" "this" {
  count = var.enabled ? 1 : 0

  vpn_gateway_id      = local.effective_vpn_gateway_id
  customer_gateway_id = local.effective_customer_gateway_id
  type                = "ipsec.1"

  static_routes_only = var.static_routes_only

  tags = merge(var.tags, {
    Name = "${var.name}-vpn"
  })
}

resource "aws_vpn_connection_route" "static" {
  for_each = var.enabled && var.static_routes_only ? toset(var.remote_cidrs) : toset([])

  vpn_connection_id      = aws_vpn_connection.this[0].id
  destination_cidr_block = each.value
}

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = var.enabled ? toset(var.route_table_ids) : toset([])

  vpn_gateway_id = local.effective_vpn_gateway_id
  route_table_id = each.value
}
