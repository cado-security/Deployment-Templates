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
| [aws_cloudwatch_log_group.cado_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.cado_log_stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_ebs_volume.data_volume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_efs_access_point.efs_access_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.efs_fs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.efs_mount_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_eip.ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_lb_target_group_attachment.registered_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_network_interface.network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.bucket_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.CadoPublicAccessBlockConfiguration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_volume_attachment.ebs_att](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_iam_role.instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | n/a | `string` | n/a | yes |
| <a name="input_configure_cloudwatch"></a> [configure\_cloudwatch](#input\_configure\_cloudwatch) | n/a | `bool` | `true` | no |
| <a name="input_feature_flag_platform_upgrade"></a> [feature\_flag\_platform\_upgrade](#input\_feature\_flag\_platform\_upgrade) | n/a | `bool` | n/a | yes |
| <a name="input_finalize_cmd"></a> [finalize\_cmd](#input\_finalize\_cmd) | n/a | `string` | n/a | yes |
| <a name="input_instance_role_name"></a> [instance\_role\_name](#input\_instance\_role\_name) | n/a | `string` | n/a | yes |
| <a name="input_instance_worker_type"></a> [instance\_worker\_type](#input\_instance\_worker\_type) | n/a | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | n/a | `string` | n/a | yes |
| <a name="input_lb_target_group_arn"></a> [lb\_target\_group\_arn](#input\_lb\_target\_group\_arn) | n/a | `string` | n/a | yes |
| <a name="input_primary_subnet"></a> [primary\_subnet](#input\_primary\_subnet) | Subnet object containing various attributes | <pre>object({<br>    id                = string<br>    cidr_block        = string<br>    availability_zone = string<br>  })</pre> | n/a | yes |
| <a name="input_proxy"></a> [proxy](#input\_proxy) | n/a | `string` | n/a | yes |
| <a name="input_proxy_cert_url"></a> [proxy\_cert\_url](#input\_proxy\_cert\_url) | n/a | `string` | n/a | yes |
| <a name="input_public_deployment"></a> [public\_deployment](#input\_public\_deployment) | n/a | `bool` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | n/a | `string` | n/a | yes |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | n/a | `string` | n/a | yes |
| <a name="input_vol_size"></a> [vol\_size](#input\_vol\_size) | n/a | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | n/a |
<!-- END_TF_DOCS -->