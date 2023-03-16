variable "subnet_ids" {
  description = "(Required) Identifiers of EC2 Subnets."
  type        = list(string)
}

variable "transit_gateway_id" {
  description = "(Required) Identifier of EC2 Transit Gateway."
  type        = string
}

variable "vpc_id" {
  description = "(Required) Identifier of EC2 VPC."
  type        = string
}

variable "appliance_mode_support" {
  description = "(Optional) Whether Appliance Mode support is enabled. If enabled, a traffic flow between a source and destination uses the same Availability Zone for the VPC attachment for the lifetime of that flow. Valid values: `disable`, `enable`. Default value: `disable`."
  type        = string
  default     = "disable"
}

variable "dns_support" {
  description = "(Optional) Whether DNS support is enabled. Valid values: `disable`, `enable`. Default value: `enable`."
  type        = string
  default     = "enable"
}

variable "tags" {
  description = "(Optional) Key-value tags for the EC2 Transit Gateway VPC Attachment. If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
}

# variable "transit_gateway_default_route_table_association" {
#   description = "(Optional) Boolean whether the VPC Attachment should be associated with the EC2 Transit Gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: `false`."
#   type = bool
#   default = false
# }

# variable "transit_gateway_default_route_table_propagation" {
#   description = "(Optional) Boolean whether the VPC Attachment should propagate routes with the EC2 Transit Gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: `false`."
#   type = bool
#   default = false
# }

variable "transit_gateway_route_table_association" {
  description = "(Optional) Boolean whether the VPC Attachment should be associated with the EC2 Transit Gateway association route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: `true`."
  type        = bool
  default     = true
}

variable "transit_gateway_route_table_propagation" {
  description = "(Optional) Boolean whether the VPC Attachment should propagate routes with the EC2 Transit Gateway propagation route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: `true`."
  type        = bool
  default     = true
}

variable "extra_propagation_ids" {
  description = "(Optional) List of additional Transit Gateway Route Table ids to propogate routes to."
  type = list(string)
  default = []
}



variable "transit_gateway_route_table_id" {
  description = "(Required) Identifier of EC2 Transit Gateway Route Table."
  type        = string
}
