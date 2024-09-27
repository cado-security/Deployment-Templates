<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_filestore_instance.beta_filestore_instance](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_filestore_instance) | resource |
| [google_compute_address.ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_attached_disk.attached_data_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_disk.data_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_instance.vm_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_filestore_instance.filestore_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance) | resource |
| [google_storage_bucket.bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boot_disk_image"></a> [boot\_disk\_image](#input\_boot\_disk\_image) | The image to use for the VM's boot disk | `string` | n/a | yes |
| <a name="input_deploy_nfs"></a> [deploy\_nfs](#input\_deploy\_nfs) | Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files. | `bool` | n/a | yes |
| <a name="input_finalize_cmd"></a> [finalize\_cmd](#input\_finalize\_cmd) | Command to run on the VM after deployment | `string` | n/a | yes |
| <a name="input_instance_worker_type"></a> [instance\_worker\_type](#input\_instance\_worker\_type) | Set Worker instance type | `string` | n/a | yes |
| <a name="input_local_workers"></a> [local\_workers](#input\_local\_workers) | Deploy without scalable workers. Only limited acquisition types will be available | `bool` | n/a | yes |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | The network configuration for the VM | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | The name of the VPC network | `any` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Value of the project id to deploy to | `string` | n/a | yes |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | Proxy URL to use for outbound connections in format / User Pass - https://user:pass@1.2.3.4:1234 \| IP Auth - https://1.2.3.4:1234 | `string` | n/a | yes |
| <a name="input_proxy_cert_url"></a> [proxy\_cert\_url](#input\_proxy\_cert\_url) | Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The zone where the VM will be deployed | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account to use for the VM | `string` | n/a | yes |
| <a name="input_subnetwork_config"></a> [subnetwork\_config](#input\_subnetwork\_config) | The subnetwork configuration for the VM | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to main vm and any spawned workers | `map(string)` | n/a | yes |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name) | n/a | `string` | n/a | yes |
| <a name="input_use_beta"></a> [use\_beta](#input\_use\_beta) | Use beta filestore to utilize NFS\_V4\_1 | `bool` | n/a | yes |
| <a name="input_use_secrets_manager"></a> [use\_secrets\_manager](#input\_use\_secrets\_manager) | Use GCP Secret Manager for storing secrets | `bool` | n/a | yes |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | The size of the VM to deploy | `string` | n/a | yes |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size) | The size of the volume to attach to the VM | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->