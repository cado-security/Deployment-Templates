## Requirements

No requirements.

## Providers

| Name                                                       | Version |
| ---------------------------------------------------------- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [google_project_iam_member.cloudbuild_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member)      | resource    |
| [google_project_iam_member.instace_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member)        | resource    |
| [google_project_iam_member.service_account_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource    |
| [google_project.current_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project)                         | data source |

## Inputs

| Name                                                               | Description                          | Type     | Default | Required |
| ------------------------------------------------------------------ | ------------------------------------ | -------- | ------- | :------: |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Value of the project id to deploy to | `string` | n/a     |   yes    |

## Outputs

No outputs.
