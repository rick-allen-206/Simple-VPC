output "ids" {
  description = "The IDs of the route tables created by this module."
  value       = aws_route_table.this[*].id
}

output "arns" {
  description = "The ARNs of the route tables created by this module."
  value       = aws_route_table.this[*].arn
}