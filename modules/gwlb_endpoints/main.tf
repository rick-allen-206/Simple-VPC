resource "aws_vpc_endpoint" "this" {
  count = length(var.subnet_ids)

  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  auto_accept       = var.auto_accept
  subnet_ids        = [var.subnet_ids[count.index]]

  tags = merge(var.tags)

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "10m")
    delete = lookup(var.timeouts, "delete", "10m")
  }
}
