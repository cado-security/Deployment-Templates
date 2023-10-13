## Requirements

No requirements.

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                   | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| [google_project_iam_custom_role.custom_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role)   | resource |
| [google_project_iam_member.project_iam_member_cado](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.user_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account)          | resource |

## Inputs

| Name                                                                  | Description                                                     | Type     | Default | Required |
| --------------------------------------------------------------------- | --------------------------------------------------------------- | -------- | ------- | :------: |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id)    | The Google Cloud project ID where the resources will be created | `string` | n/a     |   yes    |
| <a name="input_unique_name"></a> [unique\_name](#input\_unique\_name) | n/a                                                             | `string` | n/a     |   yes    |

## Outputs

| Name                                                                                | Description                                  |
| ----------------------------------------------------------------------------------- | -------------------------------------------- |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account to apply to the instance |
