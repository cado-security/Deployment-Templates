## Requirements

No requirements.

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                             | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| [google_compute_firewall.firewall_rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)         | resource |
| [google_compute_network.vpc_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)             | resource |
| [google_compute_subnetwork.custom_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name                                                                        | Description                            | Type           | Default | Required |
| --------------------------------------------------------------------------- | -------------------------------------- | -------------- | ------- | :------: |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips)       | n/a                                    | `list(string)` | n/a     |   yes    |
| <a name="input_inbound_ports"></a> [inbound\_ports](#input\_inbound\_ports) | The list of ports to open              | `list(string)` | n/a     |   yes    |
| <a name="input_region"></a> [region](#input\_region)                        | The zone where the VM will be deployed | `string`       | n/a     |   yes    |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name)       | n/a                                    | `string`       | n/a     |   yes    |

## Outputs

| Name                                                                                      | Description                              |
| ----------------------------------------------------------------------------------------- | ---------------------------------------- |
| <a name="output_custom_subnetwork"></a> [custom\_subnetwork](#output\_custom\_subnetwork) | The self link of the created subnetwork  |
| <a name="output_vpc_network"></a> [vpc\_network](#output\_vpc\_network)                   | The self link of the created VPC network |
| <a name="output_vpc_network_name"></a> [vpc\_network\_name](#output\_vpc\_network\_name)  | The name of the created VPC network      |
