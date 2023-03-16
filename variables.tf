# ─── Locals ───────────────────────────────────────────────────────────────────

locals {
  subnets_to_request = ""
  # secondary_cidr_blocks = var.network_cidr != null ? concat(formatlist(var.network_cidr), var.secondary_cidr_blocks) : var.secondary_cidr_blocks
}


# ─── Tag Variables ────────────────────────────────────────────────────────────


variable "tags" {
  description = "(Optional) A map of tags to assign to all the resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}

variable "vpc_tags" {
  description = "(Optional) A map of tags to assign to the vpc resource created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}

variable "subnet_tags" {
  description = "(Optional) A map of tags to assign to all subnet resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}

variable "route_table_tags" {
  description = "(Optional) A map of tags to assign to all route table resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}

variable "igw_tags" {
  description = "(Optional) A map of tags to assign to the Internet Gateway resource created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "(Optional) A map of tags to assign to the NAT Gateway resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "(Optional) A map of tags to assign to the NAT EIP resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}

variable "tgw_tags" {
  description = "(Optional) A map of tags to assign to the Transit Gateway resources created by this module. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}


# ─── Root Variables ───────────────────────────────────────────────────────────


variable "name" {
  description = "(Optional) The for resources created by this module. If not specified a random name will be assigned."
  type        = string
  default     = null
}

variable "env" {
  description = "(Required) The environment this VPC should be created in. This will effect things like Transit Gateway Attachment."
  type        = string

  validation {
    condition     = contains(["prd", "nonprd"], var.env)
    error_message = "Err: env must be one of <\"prd\" | \"nonprd\">"
  }
}


# ─── VPC Variables ────────────────────────────────────────────────────────────


variable "default_azs" {
  # TODO: is this expandable?
  description = "(Required) The module will create network resources for all the AZs listed. Each AZ you wish to utilize MUST be specifed here. This value can be appended to after creation to expand usable AZs. If no value is specifed the module will by default plan for 3 AZs."
  type        = list(string)
}

variable "default_3_tier_setup" {
  description = "(Otional) When set to true, the module will build a basic 3-tier setup with public subnet, private subnet, and database subnet automatically."
  type        = bool
  default     = false
}

# variable "create_public_subnet" {
#   description = "When set to `true`, and `default_3_tier_setup` is is also set to `true`, the public subnet and its route tables will be created automatically."
#   type        = bool
#   default     = true
# }

# variable "create_private_subnet" {
#   description = "When set to `true`, and `default_3_tier_setup` is is also set to `true`, the private subnet and its route tables will be created automatically."
#   type        = bool
#   default     = true
# }

# variable "create_database_subnet" {
#   description = "When set to `true`, and `default_3_tier_setup` is is also set to `true`, the database subnet and its route tables will be created automatically."
#   type        = bool
#   default     = true
# }

# TODO: Remove
# variable "cut_network_subnets_from_primary_vpc_cidr" {
#   description = "(Optional) When set to `true`, and `automatic_vpc_cidr_allocation` is also set to `true` this module will reserve the first subnet of the primary VPC address range for networking assets. This is the recommended option, but will work best if an odd number of AZs are used. Otherwise the last even subnet will not have an address space. If you are planning to allocate IP space manually, or you want to use an even number of AZs, it is REQUIRED to specify a `networking_cidr_block`."
#   type        = bool
#   default     = true
# }

variable "subnets" {
  description = "(Optional) A map with subnet details."
  type = map(object({
    azs = optional(list(string), null)
    # automatic_cidr_allocation = optional(bool, true)
    automatic_cidr_netmask = optional(list(string), null)
    cidr_blocks            = optional(list(string), null)
    shared_route_table     = optional(bool, true)
    routes                 = optional(list(map(map(string))))
    tags                   = optional(map(string), {})
  }))
  default = {}
}

variable "network_subnets" {
  description = "(Required) A map with subnet details."
  type = map(object({
    azs = optional(list(string), null)
    # automatic_cidr_allocation = optional(bool, true)
    automatic_cidr_netmask = optional(list(string), null)
    cidr_blocks            = optional(list(string), null)
    shared_route_table     = optional(bool, true)
    routes                 = optional(list(map(map(string))))
    tags                   = optional(map(string), {})
  }))
  default = {}
}

variable "automatic_vpc_cidr_allocation" {
  description = "(Optional) When set to true, the VPC's cidr range will be automatically allocated from an IPAM pool"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length`."
  type        = string
  default     = null
}

variable "network_cidr" {
  description = "(Optional) Default subnet to be used for networking services (e.g. tgw subnets or gwlbe subnets). One subnet will be created in each AZ. The size for this should be a /24. Leave this empty if you aren't sure what this is for and have enabled `automatic_cidr_allocation` and `cut_network_subnets_from_primary_vpc_cidr` which are enabled by default."
  type        = string
  default     = null
}

variable "secondary_cidr_blocks" {
  description = "(Optional) List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool."
  type        = list(string)
  default     = []
}

variable "ipv4_ipam_pool_id" {
  description = "(Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR. If none is supplied, this module will look up the pool in your current region (supplied by your provider) by filter for IPv4 pools with descriptions containing your current region. IPAM is a VPC feature that you can use to automate your IP address management workflows including assigning, tracking, troubleshooting, and auditing IP addresses across AWS Regions and accounts. Using IPAM you can monitor IP address usage throughout your AWS Organization."
  type        = string
  default     = null
}

variable "ipv4_netmask_length" {
  description = "(Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a `ipv4_ipam_pool_id`."
  type        = string
  default     = "21"
}

variable "instance_tenancy" {
  description = "(Optional) A tenancy option for instances launched into the VPC. Default is `default`, which ensures that EC2 instances launched in this VPC use the EC2 instance tenancy attribute specified when the EC2 instance is launched. The only other option is `dedicated`, which ensures that EC2 instances launched in this VPC are run on dedicated tenancy instances regardless of the tenancy attribute specified at launch. This has a dedicated per region fee of $2 per hour, plus an hourly per instance usage fee."
  type        = string
  default     = "default"
}

variable "enable_dns_support" {
  description = "(Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults to true."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "(Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true."
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "(Optional) Indicates whether Network Address Usage metrics are enabled for your VPC. Defaults to false."
  type        = bool
  default     = false
}


# ─── Internet Gateway Variables ───────────────────────────────────────────────


variable "publicly_accessible_vpc" {
  description = "(Optional) A boolean flag to configure ingress infrastructure for your VPC from the public internet. This option will also create ingress security for you. Leave this default if you aren't sure."
  type        = bool
  default     = false
}


# ─── Nat Gateway Variables ────────────────────────────────────────────────────


# variable "reuse_nat_ips" {
#   description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable"
#   type        = bool
#   default     = false
# }

# variable "external_nat_ip_ids" {
#   description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
#   type        = list(string)
#   default     = []
# }

# variable "enable_nat_gateway" {
#   description = "Should be true if you want to provision NAT Gateways for each of your private networks"
#   type        = bool
#   default     = false
# }


# ─── Transit Gateway ──────────────────────────────────────────────────────────


variable "attach_to_tgw" {
  description = "(Optional) When set to `true`, this VPC will be connected with transit gateway. Defaults to `true`."
  type        = bool
  default     = true
}

variable "tgw_id" {
  description = "(Optional) The ID of the TGW to create an attachment for."
  type        = string
  default     = "tgw-123456789"
}

variable "prd_tgw_route_table_name" {
  description = "(Optional) The name of the TGW route table to associate to. The name should match the `Name` tag's value of the route table. "
  type        = string
  default     = "default-rt"
}

variable "prd_inspection_tgw_route_table_name" {
  description = "(Optional) The name of the Inspection prd TGW route table to propagate to. The name should match the `Name` tag's value of the route table. "
  type        = string
  default     = "inspection-rt"
}

variable "nonprd_tgw_route_table_name" {
  description = "(Optional) The name of the TGW route table to associate to. The name should match the `Name` tag's value of the route table. "
  type        = string
  default     = "nonprd-rt"
}

variable "nonprd_inspection_tgw_route_table_name" {
  description = "(Optional) The name of the Inspection nonprd TGW route table to propagate to. The name should match the `Name` tag's value of the route table. "
  type        = string
  default     = "inspection-nonprd-rt"
}

variable "propagate_to_attachment_route_table" {
  description = "(Optional) If true, all routes for this VPC will be propagated to the attachment's route table. The default value if `false`."
  type        = bool
  default     = false

}


# ─── Endpoint Variables ───────────────────────────────────────────────────────


variable "endpoints" {
  description = "A map of maps containg the infomation for endpoints to add to your VPC. See the endpoints_submodule `README.md` for more information on how to use this."
  type = map(map(object({
    service             = string,
    private_dns_enabled = bool
  })))
  default = {}
}

variable "discover_gwlb" {
  description = "(Optional) When set to true the module will attempt to discover the GWLB service."
  type        = bool
  default     = true
}


# ─── Dns Variables ────────────────────────────────────────────────────────────


variable "root_hosted_zones" {
  description = "The root domain to attach to."
  type        = list(string)
  default     = ["example.com"]
}

variable "sub_hosted_zones" {
  description = "The sub-domains to attach to."
  type        = list(string)
  default     = ["test"]
}