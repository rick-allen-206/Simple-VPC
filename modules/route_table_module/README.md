<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | (Required) A list of AZs. This should match the length of the cidr\_blocks. | `list(string)` | n/a | yes |
| <a name="input_gateway_id"></a> [gateway\_id](#input\_gateway\_id) | (Optional) The gateway ID to create an association. Conflicts with `subnet_id`. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The Name of for the resources created by this module | `string` | n/a | yes |
| <a name="input_shared_route_table"></a> [shared\_route\_table](#input\_shared\_route\_table) | (Required) A bool of whether or not the route table should be shared with all the subnets or if each should recieve it's own subnet. | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Optional) A list of the subnet IDs to create an association. Conflicts with `gateway_id`. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the resource. If configured with a provider `default_tags` configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Required) The VPC ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arns"></a> [arns](#output\_arns) | The ARNs of the route tables created by this module. |
| <a name="output_ids"></a> [ids](#output\_ids) | The IDs of the route tables created by this module. |
<!-- END_TF_DOCS -->