output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "subnet_ids" {
  description = "The IDs of the subnets."
  value = {
    for k, v in module.subnets : k => v.ids
  }
}

output "subnet_arns" {
  description = "The ARNs of the subnets."
  value = {
    for k, v in module.subnets : k => v.arns
  }
}

output "route_table_ids" {
  description = "The IDs of the routing tables."
  value = {
    for k, v in module.route_tables : k => v.ids
  }
}

output "route_table_arns" {
  description = "The ARNs of the routing tables."
  value = {
    for k, v in module.route_tables : k => v.arns
  }
}


# ─── Test Output ──────────────────────────────────────────────────────────────


# output "route_table_to_route_map" {
#   value = local.route_table_to_route_map 
# }

# output "name_to_route_table_to_route_map" {
#   value = local.name_to_route_table_to_route_map
# }

# output "vpc_metadata" {
#   value = local.vpc_metadata
# }

# # TODO: remove test outputs
# output "test1" {
#   value = local.test1
# }

# output "test2" {
#   value = local.hosted_zones
# }
