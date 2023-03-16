variable "route_table_id" {
  description = "(Required) The ID of the routing table."
  type        = string
}

variable "route" {
  # TODO: add description
  description = "value"
  type        = map(map(string))
}
