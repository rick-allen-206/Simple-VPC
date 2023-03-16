# VPC Module

module should be used with odd number of AZs for HA and allow room for networking address space. The recomended value is 3 AZs which will be used by default in this module.

when using auto ip assignment, the IPAM pool in the current region (supplied by your provider) is looked up

## Providers

For this module to work, two providers must be defined with the `aws` and `aws.network` provider alises. An example providers.tf file is shown below:

```go
#######
# Backend
#######

terraform {
  required_version = "~> 1.3.1"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "my-organization"
    workspaces {
      prefix = "example-"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
  }
}

#######
# Providers
#######

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key

  assume_role {
    role_arn    = var.role_arn
    external_id = var.external_id
  }
}

provider "aws" {
  alias      = "network"
  region     = var.region
  access_key = var.network_access_key
  secret_key = var.network_secret_key

  assume_role {
    role_arn    = var.network_assume_role_arn
    external_id = var.external_id
  }
}

```

## Examples

### Example of a simple 3 tier VPC connected to TGW

*A public, private, and database subnets (as well as the required networking subnets; gwlbe and tgw) will be created.*

```go
module "example" {
  source = "./"
  providers = {
    aws         = aws
    aws.network = aws.network
  }

  env                           = "nonprd"
  automatic_vpc_cidr_allocation = true
  default_3_tier_setup          = true
}
```

### Example of a publicly accessible VPC in two AZs

```go
module "example" {
  source = "./"
  providers = {
    aws         = aws
    aws.network = aws.network
  }

  env                           = "nonprd"
  automatic_vpc_cidr_allocation = true
  default_azs                   = ["us-west-2a", "us-west-2b"]
  default_3_tier_setup          = true
  publicly_accessible_vpc       = true
  attach_to_tgw                 = false

}
```

### Example of a VPC with custom CIDR allocations and subnets

*`subnet_1` has an empty route table, while `subnet_2` will populate it's route table with the routes defined. `subnet_1` also defines specific CIDR blocks to use. Additionally, `subnet_1` also creates a shared route table for all of it's subnets, while `subnet_2` creates a route_table for each of it's subnets (which in the case of this example is two).*

```go
module "example" {
  source = "./modules/vpc"
  providers = {
    aws         = aws
    aws.network = aws.network
  }

  env                           = "nonprd"
  vpc_cidr                      = "10.0.0.0/21"
  secondary_cidr_blocks         = ["10.110.0.0/16"]
  network_cidr                  = "10.192.0.0/24"
  automatic_vpc_cidr_allocation = false

  subnets = {
    "sub1" = {
      automatic_cidr_allocation = false
      azs                       = ["us-west-2a"]
      cidr_blocks               = ["10.0.7.0/28", "10.0.7.16/28", "10.0.7.32/28"]
      shared_route_table        = true
    },
    "sub2" = {
      automatic_cidr_allocation = false
      azs                       = ["us-west-2a", "us-west-2b"]
      cidr_blocks               = ["10.0.0.128/26", "10.0.0.192/26"]
      shared_route_table = false
      routes = [
        {
          internet = {
            destination_cidr_block = "10.0.0.48/28"
            transit_gateway_id     = "1"
          },
        },
        {
          internet = {
            destination_cidr_block = "0.0.0.0/0"
            transit_gateway_id     = "1"
          },
          private = {
            destination_cidr_block = "10.0.0.0/8"
            transit_gateway_id     = "2"
          }
        },
        {
          internet = {
            destination_cidr_block = "0.0.0.0/0"
            transit_gateway_id     = "1"
          }
        }
      ]
    }
  }
}
```

## The Subnet Object

The subnet object allows for all the options detailed bellow to be specified to allow you full customization of your VPC.
There are 3 special keywords to keep in mind when naming a subnet: "private", "public", and "database". When any of these words appears in the name of your subnet it will be treated like one of the default subnets created by this module, and will automatically have routes installed in it.

```go
variable "subnets" {
  description = "(Required) A map with subnet details"
  type = map(object({
    azs                       = optional(list(string), [])
    cidr_blocks               = optional(list(string), null)
    automatic_cidr_allocation = optional(bool, false)
    cidr_netmask              = optional(list(string), null)
    shared_route_table        = optional(bool, true)
    routes                    = optional(list(map(map(string))), [])
    tags                      = optional(map(string), {})
  }))
}
```

### Argument Reference

- `azs` - (Optional) A list of AZs in which to create this subnet and it's resources.
- `cidr_blocks` - (Optional) A list of CIDR blocks to use for the subnets. This should match the number of AZs
- `automatic_cidr_allocation` - (Optional) Whether or not to automatically allocate this subnet space from the VPC CIDR.
- `cidr_netmask` - (Optional) if using `automatic_cidr_allocation`, this is required. This is a string value of the netmask to use, e.g. `"/24"`
- `shared_route_table` - (Optional) When set to `true`, a single route table is created and associated with the subnets. When set to `false`, a route table is created for each subnet and associated to them respectively.
- `routes` - (Optional) A list of map of maps containing the routes to install in the route tables created for these subnets. The top level list should contain a map for each AZ defined in `azs`. This first, map inside that list should have a key describing the route, and a value of map. The second and inner-most map will contain the key-value pairs of route settings. See the above example code for how to create this map. Also see below for the requirements of the inner-most map.
- `tags` - (Optional) A map of tags to add to all resources created for that subnet

#### Routes

In this example we have two AZs

*Here is an example of the valid values to place in the inner most dictionary:*

```go
( destination_cidr_block | destination_prefix_list_id ) = xxx
( carrier_gateway_id | core_network_arn | egress_only_gateway_id | gateway_id | instance_id | nat_gateway_id | local_gateway_id | network_interface_id | transit_gateway_id | vpc_endpoint_id | vpc_peering_connection_id ) = xxx
```

```go
[
  {
    internet = {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = "1"
    },
  },
  {
    internet = {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = "1"
    },
    private = {
      destination_cidr_block = "10.0.0.0/8"
      transit_gateway_id     = "2"
    }
  },
]
```

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.38.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.38.0 |
| <a name="provider_aws.network"></a> [aws.network](#provider\_aws.network) | >= 4.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | ./modules/endpoints | n/a |
| <a name="module_gwlb_endpoints"></a> [gwlb\_endpoints](#module\_gwlb\_endpoints) | ./modules/gwlb_endpoints | n/a |
| <a name="module_gwlbe_routes"></a> [gwlbe\_routes](#module\_gwlbe\_routes) | ./modules/route_module | n/a |
| <a name="module_igw_route_table"></a> [igw\_route\_table](#module\_igw\_route\_table) | ./modules/route_table_module | n/a |
| <a name="module_igw_routes"></a> [igw\_routes](#module\_igw\_routes) | ./modules/route_module | n/a |
| <a name="module_route_tables"></a> [route\_tables](#module\_route\_tables) | ./modules/route_table_module | n/a |
| <a name="module_routes"></a> [routes](#module\_routes) | ./modules/route_module | n/a |
| <a name="module_subnets"></a> [subnets](#module\_subnets) | ./modules/subnet_module | n/a |
| <a name="module_tgw_attachment"></a> [tgw\_attachment](#module\_tgw\_attachment) | ./modules/transit_gateway_module | n/a |
| <a name="module_tgw_routes"></a> [tgw\_routes](#module\_tgw\_routes) | ./modules/route_module | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route53_resolver_rule_association.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_rule_association) | resource |
| [aws_route53_vpc_association_authorization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_vpc_association_authorization) | resource |
| [aws_route53_zone_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint_service_allowed_principal.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_allowed_principal) | resource |
| [aws_vpc_ipv4_cidr_block_association.network_services](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_vpc_ipv4_cidr_block_association.secondary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [random_id.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_transit_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |
| [aws_ec2_transit_gateway_route_table.nonprd_inspection_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |
| [aws_ec2_transit_gateway_route_table.nonprd_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |
| [aws_ec2_transit_gateway_route_table.prd_inspection_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |
| [aws_ec2_transit_gateway_route_table.prd_tgw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway_route_table) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_resolver_rule.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_resolver_rule) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [aws_vpc_endpoint_service.public_nonprd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.public_prd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_ipam_pool.network_services_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_ipam_pool) | data source |
| [aws_vpc_ipam_pool.region_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_ipam_pool) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attach_to_tgw"></a> [attach\_to\_tgw](#input\_attach\_to\_tgw) | (Optional) When set to `true`, this VPC will be connected with transit gateway. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_automatic_vpc_cidr_allocation"></a> [automatic\_vpc\_cidr\_allocation](#input\_automatic\_vpc\_cidr\_allocation) | (Optional) When set to true, the VPC's cidr range will be automatically allocated from an IPAM pool | `bool` | `true` | no |
| <a name="input_default_3_tier_setup"></a> [default\_3\_tier\_setup](#input\_default\_3\_tier\_setup) | (Otional) When set to true, the module will build a basic 3-tier setup with public subnet, private subnet, and database subnet automatically. | `bool` | `false` | no |
| <a name="input_default_azs"></a> [default\_azs](#input\_default\_azs) | (Required) The module will create network resources for all the AZs listed. Each AZ you wish to utilize MUST be specifed here. This value can be appended to after creation to expand usable AZs. If no value is specifed the module will by default plan for 3 AZs. | `list(string)` | n/a | yes |
| <a name="input_discover_gwlb"></a> [discover\_gwlb](#input\_discover\_gwlb) | (Optional) When set to true the module will attempt to discover the GWLB service. | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_network_address_usage_metrics"></a> [enable\_network\_address\_usage\_metrics](#input\_enable\_network\_address\_usage\_metrics) | (Optional) Indicates whether Network Address Usage metrics are enabled for your VPC. Defaults to false. | `bool` | `false` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | A map of maps containg the infomation for endpoints to add to your VPC. See the endpoints\_submodule `README.md` for more information on how to use this. | <pre>map(map(object({<br>    service             = string,<br>    private_dns_enabled = bool<br>  })))</pre> | `{}` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) The environment this VPC should be created in. This will effect things like Transit Gateway Attachment. | `string` | n/a | yes |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | (Optional) A map of tags to assign to the Internet Gateway resource created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | (Optional) A tenancy option for instances launched into the VPC. Default is `default`, which ensures that EC2 instances launched in this VPC use the EC2 instance tenancy attribute specified when the EC2 instance is launched. The only other option is `dedicated`, which ensures that EC2 instances launched in this VPC are run on dedicated tenancy instances regardless of the tenancy attribute specified at launch. This has a dedicated per region fee of $2 per hour, plus an hourly per instance usage fee. | `string` | `"default"` | no |
| <a name="input_ipv4_ipam_pool_id"></a> [ipv4\_ipam\_pool\_id](#input\_ipv4\_ipam\_pool\_id) | (Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR. If none is supplied, this module will look up the pool in your current region (supplied by your provider) by filter for IPv4 pools with descriptions containing your current region. IPAM is a VPC feature that you can use to automate your IP address management workflows including assigning, tracking, troubleshooting, and auditing IP addresses across AWS Regions and accounts. Using IPAM you can monitor IP address usage throughout your AWS Organization. | `string` | `null` | no |
| <a name="input_ipv4_netmask_length"></a> [ipv4\_netmask\_length](#input\_ipv4\_netmask\_length) | (Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a `ipv4_ipam_pool_id`. | `string` | `"21"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) The for resources created by this module. If not specified a random name will be assigned. | `string` | `null` | no |
| <a name="input_nat_eip_tags"></a> [nat\_eip\_tags](#input\_nat\_eip\_tags) | (Optional) A map of tags to assign to the NAT EIP resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(string)` | `{}` | no |
| <a name="input_nat_gateway_tags"></a> [nat\_gateway\_tags](#input\_nat\_gateway\_tags) | (Optional) A map of tags to assign to the NAT Gateway resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(string)` | `{}` | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | (Optional) Default subnet to be used for networking services (e.g. tgw subnets or gwlbe subnets). One subnet will be created in each AZ. The size for this should be a /24. Leave this empty if you aren't sure what this is for and have enabled `automatic_cidr_allocation` and `cut_network_subnets_from_primary_vpc_cidr` which are enabled by default. | `string` | `null` | no |
| <a name="input_network_subnets"></a> [network\_subnets](#input\_network\_subnets) | (Required) A map with subnet details. | <pre>map(object({<br>    azs = optional(list(string), null)<br>    # automatic_cidr_allocation = optional(bool, true)<br>    automatic_cidr_netmask = optional(list(string), null)<br>    cidr_blocks            = optional(list(string), null)<br>    shared_route_table     = optional(bool, true)<br>    routes                 = optional(list(map(map(string))))<br>    tags                   = optional(map(string), {})<br>  }))</pre> | `{}` | no |
| <a name="input_nonprd_inspection_tgw_route_table_name"></a> [nonprd\_inspection\_tgw\_route\_table\_name](#input\_nonprd\_inspection\_tgw\_route\_table\_name) | (Optional) The name of the Inspection nonprd TGW route table to propagate to. The name should match the `Name` tag's value of the route table. | `string` | `"inspection-nonprd-rt"` | no |
| <a name="input_nonprd_tgw_route_table_name"></a> [nonprd\_tgw\_route\_table\_name](#input\_nonprd\_tgw\_route\_table\_name) | (Optional) The name of the TGW route table to associate to. The name should match the `Name` tag's value of the route table. | `string` | `"nonprd-rt"` | no |
| <a name="input_prd_inspection_tgw_route_table_name"></a> [prd\_inspection\_tgw\_route\_table\_name](#input\_prd\_inspection\_tgw\_route\_table\_name) | (Optional) The name of the Inspection prd TGW route table to propagate to. The name should match the `Name` tag's value of the route table. | `string` | `"inspection-rt"` | no |
| <a name="input_prd_tgw_route_table_name"></a> [prd\_tgw\_route\_table\_name](#input\_prd\_tgw\_route\_table\_name) | (Optional) The name of the TGW route table to associate to. The name should match the `Name` tag's value of the route table. | `string` | `"default-rt"` | no |
| <a name="input_propagate_to_attachment_route_table"></a> [propagate\_to\_attachment\_route\_table](#input\_propagate\_to\_attachment\_route\_table) | (Optional) If true, all routes for this VPC will be propagated to the attachment's route table. The default value if `false`. | `bool` | `false` | no |
| <a name="input_publicly_accessible_vpc"></a> [publicly\_accessible\_vpc](#input\_publicly\_accessible\_vpc) | (Optional) A boolean flag to configure ingress infrastructure for your VPC from the public internet. This option will also create ingress security for you. Leave this default if you aren't sure. | `bool` | `false` | no |
| <a name="input_root_hosted_zones"></a> [root\_hosted\_zones](#input\_root\_hosted\_zones) | The root domain to attach to. | `list(string)` | <pre>[<br>  "example.com"<br>]</pre> | no |
| <a name="input_route_table_tags"></a> [route\_table\_tags](#input\_route\_table\_tags) | (Optional) A map of tags to assign to all route table resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | (Optional) List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool. | `list(string)` | `[]` | no |
| <a name="input_sub_hosted_zones"></a> [sub\_hosted\_zones](#input\_sub\_hosted\_zones) | The sub-domains to attach to. | `list(string)` | <pre>[<br>  "test"<br>]</pre> | no |
| <a name="input_subnet_tags"></a> [subnet\_tags](#input\_subnet\_tags) | (Optional) A map of tags to assign to all subnet resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | (Optional) A map with subnet details. | <pre>map(object({<br>    azs = optional(list(string), null)<br>    # automatic_cidr_allocation = optional(bool, true)<br>    automatic_cidr_netmask = optional(list(string), null)<br>    cidr_blocks            = optional(list(string), null)<br>    shared_route_table     = optional(bool, true)<br>    routes                 = optional(list(map(map(string))))<br>    tags                   = optional(map(string), {})<br>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all the resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |
| <a name="input_tgw_id"></a> [tgw\_id](#input\_tgw\_id) | (Optional) The ID of the TGW to create an attachment for. | `string` | `"tgw-123456789"` | no |
| <a name="input_tgw_tags"></a> [tgw\_tags](#input\_tgw\_tags) | (Optional) A map of tags to assign to the Transit Gateway resources created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | (Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length`. | `string` | `null` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | (Optional) A map of tags to assign to the vpc resource created by this module. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route_table_arns"></a> [route\_table\_arns](#output\_route\_table\_arns) | The ARNs of the routing tables. |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | The IDs of the routing tables. |
| <a name="output_subnet_arns"></a> [subnet\_arns](#output\_subnet\_arns) | The ARNs of the subnets. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | The IDs of the subnets. |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->