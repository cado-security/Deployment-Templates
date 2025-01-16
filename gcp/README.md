```
  ____          _         ____                       _ _
 / ___|__ _  __| | ___   / ___|  ___  ___ _   _ _ __(_) |_ _   _
| |   / _` |/ _` |/ _ \  \___ \ / _ \/ __| | | | '__| | __| | | |
| |__| (_| | (_| | (_) |  ___) |  __/ (__| |_| | |  | | |_| |_| |
 \____\__,_|\__,_|\___/  |____/ \___|\___|\__,_|_|  |_|\__|\__, |
                                                           |___/
```
# CadoResponse GCP Terraform CLI Deployment
## Table of Contents
- [CadoResponse GCP Terraform CLI Deployment](#cadoresponse-gcp-terraform-cli-deployment)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)


This Terraform package contains instructions to configure and deploy CadoResponse on GCP platform. Further documentation can be found [here](https://docs.cadosecurity.com/cado-response/deploy/gcp/gcp-settings).

## Prerequisites

* It requires the following tools and steps to be completed before deployment:
    1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    2. [Install GCloud CLI and authenticate user for the target project](https://cloud.google.com/sdk/docs/install)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.10 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_configure"></a> [configure](#module\_configure) | ./modules/configure | n/a |
| <a name="module_deploy"></a> [deploy](#module\_deploy) | ./modules/deploy | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | The list of IPs to whitelist | `list(string)` | `[]` | no |
| <a name="input_create_cloud_build_role_service_account"></a> [create\_cloud\_build\_role\_service\_account](#input\_create\_cloud\_build\_role\_service\_account) | Create a custom Cloud Build role | `bool` | `true` | no |
| <a name="input_credentials_file"></a> [credentials\_file](#input\_credentials\_file) | Path to the credentials file | `string` | `""` | no |
| <a name="input_custom_networking"></a> [custom\_networking](#input\_custom\_networking) | Custom networking configuration. Set to null to create new resources. | <pre>object({<br/>    vpc_name           = string<br/>    public_subnet_name = string<br/>  })</pre> | `null` | no |
| <a name="input_deploy_acquisition_permissions"></a> [deploy\_acquisition\_permissions](#input\_deploy\_acquisition\_permissions) | Deploy instance with permissions needed for same project acquisitions | `bool` | `true` | no |
| <a name="input_deploy_nfs"></a> [deploy\_nfs](#input\_deploy\_nfs) | Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files. | `bool` | `true` | no |
| <a name="input_enable_platform_updates"></a> [enable\_platform\_updates](#input\_enable\_platform\_updates) | Enable platform updates, False requires updates via Terraform | `bool` | `true` | no |
| <a name="input_image"></a> [image](#input\_image) | Cado Response VM image path | `string` | `"projects/cado-public/global/images/cadoresponse"` | no |
| <a name="input_inbound_ports"></a> [inbound\_ports](#input\_inbound\_ports) | The list of ports to open | `list(string)` | <pre>[<br/>  "22",<br/>  "443"<br/>]</pre> | no |
| <a name="input_instance_worker_type"></a> [instance\_worker\_type](#input\_instance\_worker\_type) | Set Worker instance type | `string` | `"n2-highmem-8"` | no |
| <a name="input_local_ports"></a> [local\_ports](#input\_local\_ports) | The list of ports to open to speak on the local subnet | `list(string)` | <pre>[<br/>  "5432",<br/>  "9200",<br/>  "6379",<br/>  "24224"<br/>]</pre> | no |
| <a name="input_local_workers"></a> [local\_workers](#input\_local\_workers) | Deploy without scalable workers. Only limited acquisition types will be available | `bool` | `false` | no |
| <a name="input_nfs_protocol"></a> [nfs\_protocol](#input\_nfs\_protocol) | The Filestore NFS Protocol to use. | `string` | `"NFS_V4_1"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id to deploy to | `string` | n/a | yes |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | Proxy URL to use for outbound connections in format / User Pass - https://user:pass@1.2.3.4:1234 \| IP Auth - https://1.2.3.4:1234 | `string` | `""` | no |
| <a name="input_proxy_cert_url"></a> [proxy\_cert\_url](#input\_proxy\_cert\_url) | Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert. | `string` | `""` | no |
| <a name="input_proxy_whitelist"></a> [proxy\_whitelist](#input\_proxy\_whitelist) | List of IPs/domains to be included in the no\_proxy environment variable | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy to | `string` | `"us-central1"` | no |
| <a name="input_role"></a> [role](#input\_role) | The role to assign to the service account | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to main vm and any spawned workers | `map(string)` | `{}` | no |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name) | Unique name part for GCP deployments | `string` | n/a | yes |
| <a name="input_use_secrets_manager"></a> [use\_secrets\_manager](#input\_use\_secrets\_manager) | Use GCP Secret Manager for storing secrets | `bool` | `true` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Vm size to deploy | `string` | `"n2-standard-16"` | no |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size) | The volume size to deploy | `number` | `100` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->