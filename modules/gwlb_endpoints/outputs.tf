output "ids" {
  description = "List of endpoint IDs"
  value = aws_vpc_endpoint.this[*].id
}