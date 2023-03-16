resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids             = var.subnet_ids
  transit_gateway_id     = var.transit_gateway_id
  vpc_id                 = var.vpc_id
  appliance_mode_support = var.appliance_mode_support
  dns_support            = var.dns_support
  tags                   = var.tags

  # Commented out because RAM shared TGWs don't accept this parameter
  # transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  # transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
}


# ──────────────────────────────────────────────────────────────────────────────


resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  provider = aws.network
  count    = var.transit_gateway_route_table_propagation == true ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "extra_propagations" {
  provider = aws.network
  count    = length(var.extra_propagation_ids)

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.extra_propagation_ids[count.index]
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  provider = aws.network
  count    = var.transit_gateway_route_table_association == true ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
