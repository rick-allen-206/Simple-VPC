variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Default subnets IDs to associate with the VPC endpoints"
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "(Optional) The name of the endpoint service to attach Gateway Load Balancer Endpoints to. Required when `create_endpoint_service` is set to `true`."
  type        = string
  default     = null
}

variable "auto_accept" {
  description = "(Optional) Whether or not VPC endpoint connection requests to the service must be accepted by the service owner - true or false. The defalt is False."
  type        = bool
  default     = true
}

variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting VPC endpoint resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}
