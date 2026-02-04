output "vpn_gateway_id" {
  value = local.effective_vpn_gateway_id
}

output "customer_gateway_id" {
  value = local.effective_customer_gateway_id
}

output "vpn_connection_id" {
  value = try(aws_vpn_connection.this[0].id, null)
}

output "tunnel1_address" {
  value = try(aws_vpn_connection.this[0].tunnel1_address, null)
}

output "tunnel2_address" {
  value = try(aws_vpn_connection.this[0].tunnel2_address, null)
}

output "customer_gateway_configuration_xml" {
  value     = var.output_customer_gateway_configuration ? try(aws_vpn_connection.this[0].customer_gateway_configuration, null) : null
  sensitive = true
}
