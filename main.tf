# ─── Global Data ──────────────────────────────────────────────────────────────


data "aws_caller_identity" "this" {}

data "aws_region" "this" {}


# ─── Locals ───────────────────────────────────────────────────────────────────


locals {

  current_region_shorthand = join(
  "", regex("(\\w{2}).*-(\\w{2}).*-(\\d{1})", data.aws_region.this.name))

  # ! Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(
  aws_vpc_ipv4_cidr_block_association.secondary[0].vpc_id, aws_vpc.this.id, "")

  # TODO: add default AZ check to make sure there are at least as many AZs here as in each subnet block.
  default_azs = var.default_azs == null ? [
    "${data.aws_region.this.name}a",
    "${data.aws_region.this.name}b",
    "${data.aws_region.this.name}c",
  ] : var.default_azs

  unique_name = "${random_pet.this.id}-${random_id.this.id}"
  name        = var.name == null ? local.unique_name : var.name

  account_id  = data.aws_caller_identity.this.account_id
  account_arn = data.aws_caller_identity.this.arn

  public_prd_service_name    = data.aws_vpc_endpoint_service.public_prd.service_name
  public_nonprd_service_name = data.aws_vpc_endpoint_service.public_nonprd.service_name
  public_prd_service_id      = data.aws_vpc_endpoint_service.public_prd.service_id
  public_nonprd_service_id   = data.aws_vpc_endpoint_service.public_nonprd.service_id

  # subnet_scrub = { 
  #   for k, v in var.subnets : k => {
  #     azs = lookup(v, azs, null) 
  #     }
  #   }
  # this also replaces any null azs lists with the default azs

  # specified_subnets = {
  #   for k, v in var.subnets : k => {
  #     azs                       = lookup(v, "azs", local.default_azs)
  #     automatic_cidr_allocation = lookup(v, "automatic_cidr_allocation", null)
  #     automatic_cidr_netmask    = lookup(v, "automatic_cidr_netmask", null)
  #     cidr_blocks               = lookup(v, "cidr_blocks", null)
  #     shared_route_table        = lookup(v, "shared_route_table", true)
  #     #TODO: maybe do a conditional here to check if routes is == [], and if so, apply the default
  #     routes                    = lookup(v, "routes", lookup(v, "shared_route_table") == true ? [{}] : [ for az in local.default_azs : {} ])
  #     tags                      = lookup(v, "tags", {})
  #   }
  # }


  # ──────────────────────────────────────────────────────────────────────


  subnets = {
    for k, v in merge(
    var.subnets, local.network_subnets, local.default_3_tier_subnets) :
    k => v if v != null
  }

  # * Network subnets must be completely defined
  network_subnets = {
    "tgw" = {
      azs                       = local.default_azs
      automatic_cidr_allocation = false
      automatic_cidr_netmask    = null
      cidr_blocks               = slice(local.tgw_cidrsubnets, 0, length(local.default_azs))
      shared_route_table        = true
      routes                    = [for az in local.default_azs : {}]
      tags                      = {}
    }
    "gwlbe" = {
      azs                       = local.default_azs
      automatic_cidr_allocation = false
      automatic_cidr_netmask    = null
      cidr_blocks               = slice(local.gwlbe_cidrsubnets, 0, length(local.default_azs))
      shared_route_table        = false
      routes                    = [for az in local.default_azs : {}]
      tags                      = {}
    }
  }


  # ──────────────────────────────────────────────────────────────────────


  default_3_tier_subnets = var.default_3_tier_setup == true ? {

    "public" = var.publicly_accessible_vpc ? {
      azs                       = local.default_azs
      automatic_cidr_allocation = true
      automatic_cidr_netmask    = null
      cidr_blocks               = slice(local.public_cidrsubnets, 0, length(local.default_azs))
      shared_route_table        = false
      routes                    = [for i in var.default_azs : {}]
      #   for index, az in local.default_azs : {
      #     gwlbe_route = {
      #       # TODO: clean this up as a local maybe?
      #       destination_cidr_block = slice(local.public_cidrsubnets, 0, length(local.default_azs))[index],
      #       vpc_endpoint_id = "module.gwlb_endpoints[0].endpoints[index].id"
      #     }
      #   }
      # ]
      tags = {}
    } : null
    "private" = {
      azs                       = local.default_azs
      automatic_cidr_allocation = true
      automatic_cidr_netmask    = null
      cidr_blocks               = slice(local.private_cidrsubnets, 0, length(local.default_azs))
      shared_route_table        = true
      routes = [
        {
          aws2_route = {
            destination_cidr_block = "x.x.x.x/x"
            transit_gateway_id     = data.aws_ec2_transit_gateway.this.id
          },
        },
      ]
      tags = {}
    }
    "database" = {
      azs                       = local.default_azs
      automatic_cidr_allocation = true
      automatic_cidr_netmask    = null
      cidr_blocks               = slice(local.database_cidrsubnets, 0, length(local.default_azs))
      shared_route_table        = true
      routes                    = [{}]
      tags                      = {}
    }
  } : null

  # TODO: fix the cidr range

  # primary_auto_cidr = (
  #   var.cut_network_subnets_from_primary_vpc_cidr == true ? [ 
  #     for i in range(length(local.primary_cidrsubnets)-1) : local.primary_cidrsubnets[i+1]
  #   ] : local.primary_cidrsubnets
  # )

  # TODO: fix the cidr range
  # network_cidrsubnets = (
  #   var.cut_network_subnets_from_primary_vpc_cidr == true ? 
  #   cidrsubnets(local.primary_cidrsubnets[0], 2)
  #   : cidrsubnets(var.network_cidr, 2)
  # )

  # services_cidr_subnets = (
  #   cidrsubnets(local.network_cidrsubnets[0], 4, 4, 4, 4)
  # )


  # ──────────────────────────────────────────────────────────────────────


  # * A /25 remains as leftover in case the need for expansion arises
  primary_cidrsubnets = (
    var.vpc_cidr == null ?
    cidrsubnets("${data.aws_vpc.selected.cidr_block_associations[0].cidr_block}", 1, 3, 3) :
    cidrsubnets(var.vpc_cidr, 1, 3, 3)
  )

  private_cidrsubnets = (
    cidrsubnets(local.primary_cidrsubnets[0], 2, 2, 2, 2)
  )

  public_cidrsubnets = (
    cidrsubnets(local.primary_cidrsubnets[1], 2, 2, 2, 2)
  )

  database_cidrsubnets = (
    cidrsubnets(local.primary_cidrsubnets[2], 2, 2, 2, 2)
  )

  # only 2 of the 4 subnets are created below. The remaining 2 are reserved for future expansion.
  # network_cidr = (
  #   var.network_cidr == null ?
  #   "${data.aws_vpc.selected.cidr_block_associations[1].cidr_block}" :
  #   var.network_cidr
  # )


  # ──────────────────────────────────────────────────────────────────────


  network_cidrsubnets = (
    var.network_cidr == null ?
    cidrsubnets("${data.aws_vpc.selected.cidr_block_associations[1].cidr_block}", 2, 2, 2, 2) :
    cidrsubnets(var.network_cidr, 2, 2, 2, 2)
  )

  tgw_cidrsubnets = (
    cidrsubnets(local.network_cidrsubnets[0], 2, 2, 2, 2)
  )

  gwlbe_cidrsubnets = (
    cidrsubnets(local.network_cidrsubnets[1], 2, 2, 2, 2)
  )


  # ──────────────────────────────────────────────────────────────────────


  # public_cidr_subnets = (
  #   var.create_public_subnet == true ? 
  #   cidrsubnets(local.network_cidrsubnets[1], 4, 4, 4, 4)
  #   : []
  # )

  # vpc_metadata = {
  #   for name in keys(local.subnets) : name => merge([local.subnets[name], {
  #     for k, v in module.route_table[name] : "route_table_ids" => v
  #   }]...)
  # }

  vpc_metadata = merge([
    local.subnets, local.route_table_metadata
  ]...)

  sets = keys(local.subnets)

  # * Map (subnet/rout_table name) of maps (route table id) of maps (route maps)
  # * of maps (routes)
  # * Used to add route table's with their associated routes to the VPC metadata 
  route_table_metadata = {
    for name in local.sets :
    name => local.subnets[name].shared_route_table == true ? {
      module.route_tables[name].ids[0] : try(local.subnets[name].routes[0], {})
      } : {
      for index, route_table in module.route_tables[name].ids :
      module.route_tables[name].ids[index] => try(local.subnets[name].routes[index], {})
    }
  }

  # List of maps (route table id) of maps (route maps) of maps (routes)
  # Used to present a map to the route module with a key of the route table id 
  # and value of the route maps, which are maps with the route details. 
  # route_table_to_route_map = merge([
  #   for name in keys(local.subnets) :
  #   local.subnets[name].shared_route_table == true ? {
  #     module.route_table[name].ids[0] : local.subnets[name].routes[0]
  #     } : {
  #     for index, route_table in module.route_table[name].ids :
  #     module.route_table[name].ids[index] => local.subnets[name].routes[index]
  #   }
  # ]...)

  # route_table_to_route_map = local.subnets != {} ? merge([
  #   for name in keys(local.subnets) :
  #   local.subnets[name].shared_route_table == true ? {
  #     "${name}" : {
  #       "rt_id" : module.route_tables[name].ids[0],
  #       "routes" : try(local.subnets[name].routes[0], {})
  #     }
  #     } : {
  #     for index, route_table in module.route_tables[name].ids :
  #     "${name}-${local.subnets[name].azs[index]}" => {
  #       "rt_id" : module.route_tables[name].ids[index],
  #       "routes" : try(local.subnets[name].routes[index], {})
  #     }
  #   }
  # ]...) : null

  route_map = merge([
    for name in keys(local.subnets) :
    local.subnets[name].shared_route_table == true ? {
      "${name}" : {
        "rt_id"  = module.route_tables[name].ids[0],
        "routes" = coalesce(local.subnets[name].routes, [{}])[0]
      }
      } : {
      # TODO: figure out how to add AZs per subnet back in
      for index, az in module.route_tables[name].ids :
      "${name}-${coalesce(
        local.subnets[name].azs,
        local.default_azs)[index]}" => {
        "rt_id"  = module.route_tables[name].ids[index],
        "routes" = coalesce(local.subnets[name].routes, [for az in local.default_azs : {}])[index]
      }
    }
  ]...)

  # route_map = merge([
  #   for name in keys(local.subnets) :
  #   local.subnets[name].shared_route_table == true ? {
  #     "${name}" : {
  #       "rt_id" = module.route_tables[name].ids[0]
  #       "routes" = local.subnets[name].routes[0]
  #     }
  #   } : {}
  # ]...)

  # subnet_metadata = merge([
  #   for name in keys(lcoal.subnets) :
  #   local.subnets[name].shared_route_table == true ? {
  #     "${name}" : {
  #       subnet_id
  #     }
  #   }
  # ])

  # ──────────────────────────────────────────────────────────────────────


  root_hosted_zones = var.sub_hosted_zones

  realms = var.sub_hosted_zones

  hosted_zones = flatten([
    for root in local.root_hosted_zones : concat([
      for realm in local.realms : ["${realm}.${root}", "${local.current_region_shorthand}.${realm}.${root}"]
      ], [
      for root in local.root_hosted_zones : root
    ])
  ])

  hosted_zones_ids = [
    for i in range(length(local.hosted_zones)) : split("/", data.aws_route53_zone.this[i].arn)[1]
  ]


  # ──────────────────────────────────────────────────────────────────────


  default_endpoints = {
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
    },

    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
    },
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
    }
    acm = {
      service             = "acm-pca"
      private_dns_enabled = true
    },
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = false
      route_table_ids = flatten(
      [for i in keys(local.subnets) : module.route_tables[i].ids])
    },
    dynamodb = {
      service             = "dynamodb"
      service_type        = "Gateway"
      private_dns_enabled = false
      route_table_ids = flatten(
      [for i in keys(local.subnets) : module.route_tables[i].ids])
    },
  }


  # ──────────────────────────────────────────────────────────────────────


  # TODO: remove testing outputs
  test1 = data.aws_vpc_endpoint_service.public_nonprd
  test2 = module.route_tables
}


# ─── Random ───────────────────────────────────────────────────────────────────


resource "random_pet" "this" {
  length = 2
}

resource "random_id" "this" {
  byte_length = 4
}


# ─── Automatic IP Allocation ──────────────────────────────────────────────────


# TODO: fix the region bit so that it's dynamic
# TODO: make sure pool name filters are good

data "aws_vpc_ipam_pool" "region_pool" {
  count = var.automatic_vpc_cidr_allocation == true ? 1 : 0

  filter {
    name = "description"
    # values = ["*${data.aws_region.this.name}*"]
    values = ["uswe2-dev-pool-1"]
  }

  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

data "aws_vpc_ipam_pool" "network_services_pool" {
  count = var.automatic_vpc_cidr_allocation == true ? 1 : 0

  filter {
    name   = "description"
    values = ["*network-services-pool*"]
  }

  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}


# ─── VPC ──────────────────────────────────────────────────────────────────────


data "aws_vpc" "selected" {
  id = aws_vpc.this.id

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.network_services,
    aws_vpc_ipv4_cidr_block_association.secondary
  ]
}

resource "aws_vpc" "this" {
  cidr_block = (
  var.automatic_vpc_cidr_allocation == true ? null : var.vpc_cidr)

  ipv4_ipam_pool_id = (
    var.automatic_vpc_cidr_allocation == true ?
    var.ipv4_ipam_pool_id == null ?
    data.aws_vpc_ipam_pool.region_pool[0].id : var.ipv4_ipam_pool_id
    : null
  )

  ipv4_netmask_length = (var.automatic_vpc_cidr_allocation == true ?
  var.ipv4_netmask_length : null)

  instance_tenancy                     = var.instance_tenancy
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  # depends_on = [
  #   aws_vpc_ipam_pool_cidr.test
  # ]

  tags = merge(
    { "Name" = "${local.name}-vpc" },
    var.tags,
    var.vpc_tags
  )
}

# * If specified associate secondary IP ranges with VPC
resource "aws_vpc_ipv4_cidr_block_association" "network_services" {
  vpc_id = aws_vpc.this.id
  cidr_block = (
    var.network_cidr != null ?
    var.network_cidr :
    null
  )
  ipv4_ipam_pool_id = (
    var.network_cidr == null ?
    data.aws_vpc_ipam_pool.network_services_pool[0].id :
    null
  )
  ipv4_netmask_length = (
    var.network_cidr == null ?
    "24" :
    null
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count = length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr_blocks[count.index]
}


# ─── Subnet ───────────────────────────────────────────────────────────────────


module "subnets" {
  source = "./modules/subnet_module"

  for_each = local.subnets

  name   = "${local.name}-${each.key}-sub"
  vpc_id = local.vpc_id
  # TODO: add a thing here to learn which CIDR blocks to use
  cidr_blocks = each.value.cidr_blocks == null ? local.private_cidrsubnets : each.value.cidr_blocks
  azs         = coalesce(each.value.azs, local.default_azs)

  tags = merge(
    var.tags,
    var.subnet_tags,
    each.value.tags
  )

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.network_services,
    aws_vpc_ipv4_cidr_block_association.secondary
  ]
}

# ─── Route Tables ─────────────────────────────────────────────────────────────


# * Map of route table IDs formated with the name of the route_table as the key, and the IDs of the route tables as the values. ex: { "route_table_1" : ["id1", "id2"] }
# ? do I still need this local?

module "route_tables" {
  source = "./modules/route_table_module"

  for_each = local.subnets

  name               = "${local.name}-${each.key}-rt"
  vpc_id             = local.vpc_id
  shared_route_table = each.value.shared_route_table
  subnet_ids         = module.subnets[each.key].ids
  azs                = coalesce(each.value.azs, local.default_azs) #local.default_azs #try(each.value.azs, local.default_azs)

  tags = merge(
    var.tags,
    var.subnet_tags,
    each.value.tags
  )

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.network_services,
    aws_vpc_ipv4_cidr_block_association.secondary
  ]

}


# ─── Routes ───────────────────────────────────────────────────────────────────


module "routes" {
  source = "./modules/route_module"

  for_each = local.route_map

  route_table_id = each.value.rt_id
  route          = each.value.routes

  depends_on = [
    module.route_tables
  ]
}


# ─── Internet Gateway ─────────────────────────────────────────────────────────


resource "aws_internet_gateway" "this" {
  count = var.publicly_accessible_vpc ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { "Name" = "${local.name}-igw" },
    var.tags,
    var.igw_tags,
  )
}

module "igw_route_table" {
  source = "./modules/route_table_module"
  count  = var.publicly_accessible_vpc ? 1 : 0

  name       = "${local.name}-igw-rt"
  vpc_id     = local.vpc_id
  gateway_id = aws_internet_gateway.this[0].id
  azs        = local.default_azs

  tags = merge(
    var.tags,
  )

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.network_services,
    aws_vpc_ipv4_cidr_block_association.secondary
  ]

}

module "igw_routes" {
  source = "./modules/route_module"
  count  = var.publicly_accessible_vpc ? length(module.gwlb_endpoints[0].ids) : 0

  route_table_id = module.igw_route_table[0].ids[0]
  route = {
    gwlbe_route = {
      # destination_cidr_block = module.subnets["gwlbe"].cidr_blocks[count.index]
      destination_cidr_block = module.subnets["public"].cidr_blocks[count.index]
      vpc_endpoint_id        = module.gwlb_endpoints[0].ids[count.index]
    }
  }

  depends_on = [
    module.route_tables
  ]
}


# ─── Nat Gateway ──────────────────────────────────────────────────────────────


# locals {
#   nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : try(aws_eip.nat[*].id, [])
# }

# resource "aws_eip" "nat" {
#   count = var.enable_nat_gateway && var.reuse_nat_ips == false ? length(var.default_azs) : 0

#   vpc = true

#   tags = merge(
#     { "Name" = "${local.name}-nat-eip" },
#     var.tags,
#     var.nat_eip_tags,
#   )
# }

# resource "aws_nat_gateway" "this" {
#   count = var.enable_nat_gateway ? length(var.default_azs) : 0

#   allocation_id = element(local.nat_gateway_ips, count.index, )
#   subnet_id     = element(aws_subnet.public[*].id, count.index, )

#   tags = merge(
#     { "Name" = "${local.name}-nat-${local.subnets.azs[count.index]}" },
#     var.tags,
#     var.nat_gateway_tags,
#   )

#   depends_on = [aws_internet_gateway.this]
# }


# ─── Transit Gateway ──────────────────────────────────────────────────────────


data "aws_ec2_transit_gateway" "this" {
  provider = aws.network
  filter {
    name = "transit-gateway-id"
    # ! TODO: fix this hardcoded TGW ID
    values = [var.tgw_id]
  }
}

data "aws_ec2_transit_gateway_route_table" "prd_tgw_rt" {
  provider = aws.network

  filter {
    name   = "transit-gateway-id"
    values = [data.aws_ec2_transit_gateway.this.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.prd_tgw_route_table_name]
  }
}

data "aws_ec2_transit_gateway_route_table" "nonprd_tgw_rt" {
  provider = aws.network

  filter {
    name   = "transit-gateway-id"
    values = [data.aws_ec2_transit_gateway.this.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.nonprd_tgw_route_table_name]
  }
}

data "aws_ec2_transit_gateway_route_table" "prd_inspection_tgw_rt" {
  provider = aws.network

  filter {
    name   = "transit-gateway-id"
    values = [data.aws_ec2_transit_gateway.this.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.prd_inspection_tgw_route_table_name]
  }
}

data "aws_ec2_transit_gateway_route_table" "nonprd_inspection_tgw_rt" {
  provider = aws.network

  filter {
    name   = "transit-gateway-id"
    values = [data.aws_ec2_transit_gateway.this.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.nonprd_inspection_tgw_route_table_name]
  }
}

module "tgw_attachment" {
  source = "./modules/transit_gateway_module"
  providers = {
    aws         = aws
    aws.network = aws.network
  }
  count = var.attach_to_tgw ? 1 : 0

  vpc_id             = local.vpc_id
  subnet_ids         = module.subnets["tgw"].ids
  transit_gateway_id = data.aws_ec2_transit_gateway.this.id

  transit_gateway_route_table_id = (
    var.env == "prd" ? data.aws_ec2_transit_gateway_route_table.prd_tgw_rt.id :
    data.aws_ec2_transit_gateway_route_table.nonprd_tgw_rt.id
  )

  transit_gateway_route_table_propagation = (
    var.propagate_to_attachment_route_table
  )

  extra_propagation_ids = (var.env == "prd" ?
    [
      data.aws_ec2_transit_gateway_route_table.prd_inspection_tgw_rt.id,
      data.aws_ec2_transit_gateway_route_table.nonprd_inspection_tgw_rt.id
      ] : [
      data.aws_ec2_transit_gateway_route_table.nonprd_inspection_tgw_rt.id
    ]
  )

  tags = merge(
    { "Name" = "${local.name}-tgw-attachment" },
    var.tags,
    var.tgw_tags,
  )

  depends_on = [
    module.subnets
  ]
}

module "tgw_routes" {
  source = "./modules/route_module"
  count  = var.attach_to_tgw && contains(keys(local.subnets), "private") ? length(module.route_tables["private"].ids) : 0

  route_table_id = module.route_tables["private"].ids[0]
  route = {
    tgw_route = {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = data.aws_ec2_transit_gateway.this.id
    }
  }

  depends_on = [
    module.route_tables
  ]
}


# ─── R53 Hosted Zone Association ──────────────────────────────────────────────


data "aws_route53_zone" "this" {
  provider = aws.network
  count    = length(local.hosted_zones)

  name         = local.hosted_zones[count.index]
  private_zone = true
}

data "aws_route53_resolver_rule" "example" {
  name        = "example"
  domain_name = "example.com"
  rule_type   = "FORWARD"
}


# ──────────────────────────────────────────────────────────────────────────────


resource "aws_route53_vpc_association_authorization" "this" {
  provider = aws.network
  count    = length(local.hosted_zones)

  vpc_id  = local.vpc_id
  zone_id = local.hosted_zones_ids[count.index]
}

resource "aws_route53_zone_association" "this" {
  count = length(local.hosted_zones)

  vpc_id  = local.vpc_id
  zone_id = local.hosted_zones_ids[count.index]

  depends_on = [
    aws_route53_vpc_association_authorization.this
  ]
}


# ──────────────────────────────────────────────────────────────────────────────


resource "aws_route53_resolver_rule_association" "example" {
  resolver_rule_id = data.aws_route53_resolver_rule.example.id
  vpc_id           = local.vpc_id
}

# ─── Gateway Gatewayloadbalancer Endpoints ────────────────────────────────────


data "aws_vpc_endpoint_service" "public_nonprd" {
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["public_nonprd-endpoint-service"]
  }
}

data "aws_vpc_endpoint_service" "public_prd" {
  provider = aws.network
  filter {
    name   = "tag:Name"
    values = ["public_prd-endpoint-service"]
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  provider = aws.network
  count    = var.publicly_accessible_vpc && var.discover_gwlb ? 1 : 0

  vpc_endpoint_service_id = (var.env == "prd" ?
  local.public_prd_service_id : local.public_nonprd_service_id)
  principal_arn = local.account_arn
}

module "gwlb_endpoints" {
  source = "./modules/gwlb_endpoints"
  count  = var.publicly_accessible_vpc ? 1 : 0

  service_name = (var.env == "prd" ? local.public_prd_service_name :
  local.public_nonprd_service_name)

  vpc_id     = local.vpc_id
  subnet_ids = module.subnets["gwlbe"].ids

  # TODO: Fix tags later
  tags = merge(var.tags)

  depends_on = [
    aws_vpc_endpoint_service_allowed_principal.this,
    module.subnets
  ]
}

module "gwlbe_routes" {
  source = "./modules/route_module"
  count  = var.publicly_accessible_vpc && contains(keys(local.subnets), "public") ? length(module.gwlb_endpoints[0].ids) : 0

  route_table_id = module.route_tables["public"].ids[count.index]
  route = {
    gwlbe_route = {
      # destination_cidr_block = module.subnets["gwlbe"].cidr_blocks[count.index]
      destination_cidr_block = "0.0.0.0/0"
      vpc_endpoint_id        = module.gwlb_endpoints[0].ids[count.index]
    }
  }

  depends_on = [
    module.route_tables
  ]
}


# ─── Security Groups ──────────────────────────────────────────────────────────


resource "aws_security_group" "this" {
  name_prefix = "allow443"
  description = "Allow TLS inbound traffic on port 443 from IPs in this VPC."
  vpc_id      = local.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.aws_vpc.selected.cidr_block_associations[*].cidr_block
  }

  # TODO: Fix tags later
  tags = merge(var.tags)
}


# ─── Endpoints ────────────────────────────────────────────────────────────────


module "endpoints" {
  source = "./modules/endpoints"

  vpc_id             = local.vpc_id
  security_group_ids = [aws_security_group.this.id]

  endpoints = merge(local.default_endpoints, var.endpoints)
  subnet_ids = (
    contains(keys(local.subnets), "private") ? module.subnets["private"].ids :
    module.subnets["tgw"].ids
  )

  tags = var.tags

  depends_on = [
    module.subnets
  ]
}
