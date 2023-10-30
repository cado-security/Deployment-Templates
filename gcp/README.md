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

## Requirements

| Name                                                             | Version |
| ---------------------------------------------------------------- | ------- |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.72 |

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 4.73.0  |

## Modules

| Name                                                               | Source               | Version |
| ------------------------------------------------------------------ | -------------------- | ------- |
| <a name="module_deploy"></a> [deploy](#module\_deploy)             | ./modules/deploy     | n/a     |
| <a name="module_iam"></a> [iam](#module\_iam)                      | ./modules/iam        | n/a     |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a     |

## Resources

| Name                                                                                                                                 | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [google_compute_image.custom_image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |

## Inputs

| Name                                                                                 | Description                                      | Type           | Default                                                                                   | Required |
| ------------------------------------------------------------------------------------ | ------------------------------------------------ | -------------- | ----------------------------------------------------------------------------------------- | :------: |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips)                | The list of IPs to whitelist                     | `list(string)` | `[]`                                                                                      |    no    |
| <a name="input_credentials_file"></a> [credentials\_file](#input\_credentials\_file) | Path to the credentials file                     | `string`       | `""`                                                                                      |    no    |
| <a name="input_finalize_cmd"></a> [finalize\_cmd](#input\_finalize\_cmd)             | Command to run on the VM after deployment        | `string`       | `"sudo /home/admin/processor/release/finalize.sh --main"`                                 |    no    |
| <a name="input_image"></a> [image](#input\_image)                                    | Cado Response VM image path                      | `string`       | `"https://www.googleapis.com/compute/v1/projects/cado-public/global/images/cadoresponse"` |    no    |
| <a name="input_inbound_ports"></a> [inbound\_ports](#input\_inbound\_ports)          | The list of ports to open                        | `list(string)` | <pre>[<br>  "22",<br>  "443",<br>  "5432",<br>  "9200",<br>  "6379"<br>]</pre>            |    no    |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id)                   | Project id to deploy to                          | `string`       | n/a                                                                                       |   yes    |
| <a name="input_region"></a> [region](#input\_region)                                 | Region to deploy to                              | `string`       | `"us-central1"`                                                                           |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                       | Tags to apply to main vm and any spawned workers | `map(string)`  | `{}`                                                                                      |    no    |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name)                | Unique name part for GCP deployments             | `string`       | n/a                                                                                       |   yes    |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size)                            | Vm size to deploy                                | `string`       | `"e2-standard-4"`                                                                         |    no    |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size)                         | The volume size to deploy                        | `number`       | `100`                                                                                     |    no    |

## Outputs

No outputs.
