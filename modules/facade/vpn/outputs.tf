output "vpn_gateway_id" {
  value = try(module.aws_vpn[0].vpn_gateway_id, null)
}

output "peer_gateway_id" {
  value = try(module.aws_vpn[0].customer_gateway_id, null)
}

output "vpn_connection_id" {
  value = try(module.aws_vpn[0].vpn_connection_id, null)
}

output "tunnel1_address" {
  value = try(module.aws_vpn[0].tunnel1_address, null)
}

output "tunnel2_address" {
  value = try(module.aws_vpn[0].tunnel2_address, null)
}

output "tunnel_endpoints" {
  value = compact([
    try(module.aws_vpn[0].tunnel1_address, null),
    try(module.aws_vpn[0].tunnel2_address, null),
  ])
}

output "peer_configuration" {
  value     = try(module.aws_vpn[0].customer_gateway_configuration_xml, null)
  sensitive = true
}