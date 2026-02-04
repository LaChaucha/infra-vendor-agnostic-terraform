output "network_id" {
  value = try(module.aws_network[0].vpc_id, null)
}

output "private_subnet_ids" {
  value = try(module.aws_network[0].private_subnet_ids, {})
}

output "private_route_table_id" {
  value = try(module.aws_network[0].private_route_table_id, null)
}