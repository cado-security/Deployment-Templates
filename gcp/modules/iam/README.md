<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_custom_role.custom_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.project_iam_member_cado](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.user_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deploy_acquisition_permissions"></a> [deploy\_acquisition\_permissions](#input\_deploy\_acquisition\_permissions) | Whether to deploy the acquisition permissions | `bool` | n/a | yes |
| <a name="input_enable_platform_updates"></a> [enable\_platform\_updates](#input\_enable\_platform\_updates) | Enable platform updates, False requires updates via Terraform | `bool` | n/a | yes |
| <a name="input_local_workers"></a> [local\_workers](#input\_local\_workers) | Deploy without scalable workers. Only limited acquisition types will be available | `bool` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where the resources will be created | `string` | n/a | yes |
| <a name="input_role"></a> [role](#input\_role) | The role to assign to the service account | `string` | `""` | no |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name) | n/a | `string` | n/a | yes |
| <a name="input_use_secrets_manager"></a> [use\_secrets\_manager](#input\_use\_secrets\_manager) | Use GCP Secret Manager for storing secrets | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account to apply to the instance |
<!-- END_TF_DOCS -->