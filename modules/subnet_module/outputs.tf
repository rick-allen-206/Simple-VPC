output "ids" {
  description = "The IDs of the subnets created by this module."
  value       = aws_subnet.this[*].id
}

output "cidr_blocks" {
  description = "The CIDR blocks of the subnets created by this module."
  value       = var.cidr_blocks[*]
}

output "arns" {
  description = "The ARNs of the subnets created by this module."
  value       = aws_subnet.this[*].arn
}