resource "aws_route" "this" {
  for_each = var.route

  route_table_id = var.route_table_id

  
  # ──────────────────────────────────────────────────────────────────────
  

  destination_cidr_block     = lookup(each.value, "destination_cidr_block", null)
  destination_prefix_list_id = lookup(each.value, "destination_prefix_list_id", null)


  # ──────────────────────────────────────────────────────────────────────

  
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  core_network_arn          = lookup(each.value, "core_network_arn", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  gateway_id                = lookup(each.value, "gateway_id", null)
  instance_id               = lookup(each.value, "instance_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_endpoint_id           = lookup(each.value, "vpc_endpoint_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connetion_id", null)
}

