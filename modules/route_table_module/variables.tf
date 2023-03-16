variable "name" {
  description = "(Required) The Name of for the resources created by this module"
  type        = string
}

variable "vpc_id" {
  description = "(Required) The VPC ID."
  type        = string
}

variable "shared_route_table" {
  description = "(Required) A bool of whether or not the route table should be shared with all the subnets or if each should recieve it's own subnet."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "(Optional) A list of the subnet IDs to create an association. Conflicts with `gateway_id`."
  type        = list(string)
  default     = null
}

variable "gateway_id" {
  description = "(Optional) The gateway ID to create an association. Conflicts with `subnet_id`."
  type        = string
  default     = null
}

variable "azs" {
  description = "(Required) A list of AZs. This should match the length of the cidr_blocks."
  type        = list(string)
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the resource. If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
}
