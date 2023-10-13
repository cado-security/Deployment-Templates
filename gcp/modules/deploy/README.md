## Requirements

No requirements.

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                    | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [google_compute_address.ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address)                             | resource    |
| [google_compute_attached_disk.attached_data_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource    |
| [google_compute_disk.data_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk)                            | resource    |
| [google_compute_instance.vm_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)                  | resource    |
| [google_filestore_instance.filestore_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance)       | resource    |
| [google_storage_bucket.bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket)                           | resource    |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones)                       | data source |

## Inputs

| Name                                                                                    | Description                                      | Type          | Default | Required |
| --------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------- | ------- | :------: |
| <a name="input_boot_disk_image"></a> [boot\_disk\_image](#input\_boot\_disk\_image)     | The image to use for the VM's boot disk          | `string`      | n/a     |   yes    |
| <a name="input_finalize_cmd"></a> [finalize\_cmd](#input\_finalize\_cmd)                | Command to run on the VM after deployment        | `string`      | n/a     |   yes    |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config)          | The network configuration for the VM             | `string`      | n/a     |   yes    |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name)                | The name of the VPC network                      | `any`         | n/a     |   yes    |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id)                      | Value of the project id to deploy to             | `string`      | n/a     |   yes    |
| <a name="input_region"></a> [region](#input\_region)                                    | The zone where the VM will be deployed           | `string`      | n/a     |   yes    |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account)       | The service account to use for the VM            | `string`      | n/a     |   yes    |
| <a name="input_subnetwork_config"></a> [subnetwork\_config](#input\_subnetwork\_config) | The subnetwork configuration for the VM          | `any`         | n/a     |   yes    |
| <a name="input_tags"></a> [tags](#input\_tags)                                          | Tags to apply to main vm and any spawned workers | `map(string)` | n/a     |   yes    |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name)                   | n/a                                              | `string`      | n/a     |   yes    |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size)                               | The size of the VM to deploy                     | `string`      | n/a     |   yes    |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size)                            | The size of the volume to attach to the VM       | `number`      | n/a     |   yes    |

## Outputs

No outputs.
