```
  ____          _         ____                       _ _         
 / ___|__ _  __| | ___   / ___|  ___  ___ _   _ _ __(_) |_ _   _ 
| |   / _` |/ _` |/ _ \  \___ \ / _ \/ __| | | | '__| | __| | | |
| |__| (_| | (_| | (_) |  ___) |  __/ (__| |_| | |  | | |_| |_| |
 \____\__,_|\__,_|\___/  |____/ \___|\___|\__,_|_|  |_|\__|\__, |
                                                           |___/ 
```
# CadoResponse AWS Terraform CLI Deployment
## Table of Contents
- [CadoResponse AWS Terraform CLI Deployment](#cadoresponse-aws-terraform-cli-deployment)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Deploy](#deploy)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)


This Terraform package contains instructions to configure and deploy CadoResponse on AWS platform. Further documentation can be found [here](https://docs.cadosecurity.com/cado-response/deploy/aws/overview).

## Prerequisites

* It requires the following tools and steps to be completed before deployment:
    1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    2. [Install AWS CLI and authenticate user for the target account](hhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    3. Adjust the provided `awsVars.tfvars` file.

## Deploy
* Inside this directory, deploy with these commands:
  1. initialize terraform and required modules: `terraform init`
  2. Confirm configuration and view deployment plan: `terraform plan -var-file="awsVars.tfvars"` 
  3. Deploy: `terraform apply -var-file="awsVars.tfvars"` 

To teardown the deployed stack: `terraform destroy -var-file="awsVars.tfvars"`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.31 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deploy"></a> [deploy](#module\_deploy) | ./modules/deploy | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Cado Response AMI ID | `string` | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate arn to use for the ALB | `string` | `""` | no |
| <a name="input_configure_cloudwatch"></a> [configure\_cloudwatch](#input\_configure\_cloudwatch) | Create resources enabling Cado logs to be viewed in CloudWatch | `bool` | `true` | no |
| <a name="input_custom_networking"></a> [custom\_networking](#input\_custom\_networking) | Custom networking configuration. Set to null to create new resources. | <pre>object({<br>    vpc_id             = string<br>    public_subnet_id   = string<br>    private_subnet_id  = string<br>    public_subnet_b_id = string<br>  })</pre> | `null` | no |
| <a name="input_deploy_nfs"></a> [deploy\_nfs](#input\_deploy\_nfs) | Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files. | `bool` | `true` | no |
| <a name="input_feature_flag_platform_upgrade"></a> [feature\_flag\_platform\_upgrade](#input\_feature\_flag\_platform\_upgrade) | n/a | `bool` | `false` | no |
| <a name="input_finalize_cmd"></a> [finalize\_cmd](#input\_finalize\_cmd) | Finalize command | `string` | `"sudo /home/admin/processor/release/finalize.sh --main"` | no |
| <a name="input_http_location"></a> [http\_location](#input\_http\_location) | IP address to allow http access from | `list(string)` | n/a | yes |
| <a name="input_instance_worker_type"></a> [instance\_worker\_type](#input\_instance\_worker\_type) | Set Worker instance type | `string` | `"i4i.2xlarge"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | n/a | `string` | n/a | yes |
| <a name="input_load_balancer_access_logs_bucket_name"></a> [load\_balancer\_access\_logs\_bucket\_name](#input\_load\_balancer\_access\_logs\_bucket\_name) | S3 bucket name to store load balancer access logs. Off by default unless set. | `string` | `""` | no |
| <a name="input_load_balancer_delete_protection"></a> [load\_balancer\_delete\_protection](#input\_load\_balancer\_delete\_protection) | Enable or disable deletion protection for the load balancer via API (Terraform) | `bool` | `true` | no |
| <a name="input_private_load_balancer"></a> [private\_load\_balancer](#input\_private\_load\_balancer) | To determine if we should deploy an internal load balancer | `bool` | `false` | no |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | Proxy URL to use for outbound connections in format / User Pass - https://user:pass@1.2.3.4:1234 \| IP Auth - https://1.2.3.4:1234 | `string` | `""` | no |
| <a name="input_proxy_cert_url"></a> [proxy\_cert\_url](#input\_proxy\_cert\_url) | Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert. | `string` | `""` | no |
| <a name="input_public_deployment"></a> [public\_deployment](#input\_public\_deployment) | To determine if we should deploy without a public IP | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy to | `string` | `"us-west-1"` | no |
| <a name="input_ssh_location"></a> [ssh\_location](#input\_ssh\_location) | IP address to allow ssh access from | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to main vm and any spawned workers | `map(string)` | `{}` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | VM size to deploy | `string` | `"m5.4xlarge"` | no |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size) | Volume size to deploy | `number` | `100` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->