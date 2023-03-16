resource "aws_route_table" "this" {
  count = (
    length(var.azs) > 0 ?
    var.shared_route_table ?
    1 : length(var.azs)
    : 0
  )

  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    (
      var.shared_route_table ?
      { "Name" : "${var.name}" }
      : { "Name" : "${var.name}-${var.azs[count.index]}" }
    )
  )
}

resource "aws_route_table_association" "this" {
  count = (
    length(var.azs) > 0 ? var.subnet_ids == null && var.gateway_id != null ? 
    1 : length(var.azs) : 0
  )
  
  route_table_id = ( var.shared_route_table ? 
    aws_route_table.this[0].id : aws_route_table.this[count.index].id )
  subnet_id      = var.gateway_id == null ? var.subnet_ids[count.index] : null
  gateway_id     = var.subnet_ids == null ? var.gateway_id : null
}