# TODO: add divisible local for length of list so that len subnets don't have to match len AZs (total values / count.index rounded up)
# TODO: add automatic address allocation

resource "aws_subnet" "this" {
  count = length(var.azs)

  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_blocks[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.tags,
    { "Name" : "${var.name}-${var.azs[count.index]}" }
  )
}
