variable "name" {
  description = "(Required) The Name of for the resources created by this module. `-sub-<az-name>` will be appended to the name."
  type        = string
}

variable "vpc_id" {
  description = "(Required) The VPC ID."
  type        = string
}

# TODO: make this optional and add automatic address allocation
variable "cidr_blocks" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length`."
  type        = list(string)
}

variable "azs" {
  description = "(Required) AZ for the subnet."
  type        = list(string)
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the resource. If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
}
