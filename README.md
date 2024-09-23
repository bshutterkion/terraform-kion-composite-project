<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kion"></a> [kion](#requirement\_kion) | ~> 0.3.18 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kion"></a> [kion](#provider\_kion) | ~> 0.3.18 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_rules"></a> [cloud\_rules](#module\_cloud\_rules) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/cloud-rule | n/a |
| <a name="module_cloudformation_templates"></a> [cloudformation\_templates](#module\_cloudformation\_templates) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-cloudformation-template | n/a |
| <a name="module_compliance_checks"></a> [compliance\_checks](#module\_compliance\_checks) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/compliance-check | n/a |
| <a name="module_compliance_standards"></a> [compliance\_standards](#module\_compliance\_standards) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/compliance-standard | n/a |
| <a name="module_iam_policies"></a> [iam\_policies](#module\_iam\_policies) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-iam-policy | n/a |
| <a name="module_project"></a> [project](#module\_project) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project | n/a |
| <a name="module_project_cars"></a> [project\_cars](#module\_project\_cars) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project-cloud-access-role | n/a |
| <a name="module_project_permission_mapping"></a> [project\_permission\_mapping](#module\_project\_permission\_mapping) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project-permission-mapping | n/a |
| <a name="module_scps"></a> [scps](#module\_scps) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-service-control-policy | n/a |
| <a name="module_user_groups"></a> [user\_groups](#module\_user\_groups) | /Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/user-group | n/a |

## Resources

| Name | Type |
|------|------|
| [kion_ou.project_ou](https://registry.terraform.io/providers/kionsoftware/kion/latest/docs/data-sources/ou) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_role_id"></a> [app\_role\_id](#input\_app\_role\_id) | The application role ID to assign the created user groups. | `number` | `null` | no |
| <a name="input_cloud_access_roles"></a> [cloud\_access\_roles](#input\_cloud\_access\_roles) | List of cloud access roles to create. | <pre>list(object({<br>    name              = string<br>    aws_iam_role_name = string<br>    aws_iam_policies = object({<br>      user_managed   = optional(list(object({ template = string })), [])<br>      system_managed = optional(list(string), [])<br>    })<br>    web_access             = optional(bool, true)<br>    short_term_access_keys = optional(bool, true)<br>    long_term_access_keys  = optional(bool, false)<br>    user_groups            = optional(list(string), [])<br>    users                  = optional(list(string), [])<br>  }))</pre> | `[]` | no |
| <a name="input_cloud_provider_id"></a> [cloud\_provider\_id](#input\_cloud\_provider\_id) | The ID of the cloud provider. | `number` | `1` | no |
| <a name="input_cloud_rule_attachments"></a> [cloud\_rule\_attachments](#input\_cloud\_rule\_attachments) | Attachments for the cloud rule. | <pre>object({<br>    aws_iam_policies = optional(object({<br>      user_managed   = optional(list(string))<br>      system_managed = optional(list(string))<br>    }))<br>    compliance_standard = object({<br>      compliance_checks = object({<br>        user_managed = list(object({<br>          template = string<br>          overrides = optional(object({<br>            regions               = optional(list(string))<br>            auto_archive          = optional(bool)<br>            all_regions           = optional(bool)<br>            severity              = optional(string)<br>            frequency             = optional(number)<br>            frequency_type        = optional(string)<br>            compliance_check_type = optional(string)<br>            csp                   = optional(string)<br>          }))<br>        }))<br>        system_managed = list(object({<br>          template = string<br>          overrides = optional(object({<br>            severity       = optional(string)<br>            frequency      = optional(number)<br>            frequency_type = optional(string)<br>          }))<br>        }))<br>      })<br>    })<br>  })</pre> | `null` | no |
| <a name="input_cloud_rules"></a> [cloud\_rules](#input\_cloud\_rules) | List of cloud rules. | <pre>list(object({<br>    name        = string<br>    description = optional(string)<br>    cloud_rule_attachments = optional(object({<br>      scps = optional(list(string))<br>      aws_iam_policies = optional(object({<br>        user_managed   = optional(list(object({ template = string })), [])<br>        system_managed = optional(list(string), [])<br>      }))<br>    }))<br>    compliance_standards = optional(list(string))<br>  }))</pre> | `[]` | no |
| <a name="input_cloudformation_templates"></a> [cloudformation\_templates](#input\_cloudformation\_templates) | List of CloudFormation templates to create | <pre>list(object({<br>    name                   = string<br>    regions                = optional(list(string), ["*"])<br>    description            = optional(string)<br>    policy_template        = string<br>    region                 = optional(string)<br>    sns_arns               = optional(string)<br>    template_parameters    = optional(string)<br>    termination_protection = optional(bool, false)<br>    tags                   = optional(map(string), {})<br>  }))</pre> | `[]` | no |
| <a name="input_compliance_check_type_id"></a> [compliance\_check\_type\_id](#input\_compliance\_check\_type\_id) | The ID of the compliance check type. | `number` | `2` | no |
| <a name="input_compliance_standards"></a> [compliance\_standards](#input\_compliance\_standards) | List of compliance standards. | <pre>list(object({<br>    name        = string<br>    description = optional(string)<br>    compliance_checks = optional(object({<br>      user_managed = optional(list(object({<br>        template = string<br>        overrides = optional(object({<br>          regions               = optional(list(string))<br>          auto_archive          = optional(bool)<br>          all_regions           = optional(bool)<br>          severity              = optional(string)<br>          frequency             = optional(number)<br>          frequency_type        = optional(string)<br>          compliance_check_type = optional(string)<br>          csp                   = optional(string)<br>        }))<br>      })), [])<br>      system_managed = optional(list(object({<br>        template = string<br>        overrides = optional(object({<br>          severity       = optional(string)<br>          frequency      = optional(number)<br>          frequency_type = optional(string)<br>        }))<br>      })), [])<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the Project. | `string` | `null` | no |
| <a name="input_frequency_minutes"></a> [frequency\_minutes](#input\_frequency\_minutes) | Frequency of the compliance check in minutes. | `number` | `60` | no |
| <a name="input_frequency_type_id"></a> [frequency\_type\_id](#input\_frequency\_type\_id) | The frequency type ID. | `number` | `2` | no |
| <a name="input_iam_policies"></a> [iam\_policies](#input\_iam\_policies) | List of IAM policies to create and attach. | <pre>list(object({<br>    name                 = string<br>    policy_template      = optional(string)<br>    attach_to_cloud_rule = optional(bool, false)<br>    attach_to_car        = optional(string)<br>    type                 = string<br>  }))</pre> | `[]` | no |
| <a name="input_idms_id"></a> [idms\_id](#input\_idms\_id) | IDMS ID for the user groups. | `number` | `null` | no |
| <a name="input_is_all_regions"></a> [is\_all\_regions](#input\_is\_all\_regions) | Whether the compliance check applies to all regions. | `bool` | `true` | no |
| <a name="input_is_auto_archived"></a> [is\_auto\_archived](#input\_is\_auto\_archived) | Whether the compliance check is auto-archived. | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of labels to assign to the Project. | <pre>map(object({<br>    value = string<br>    color = string<br>  }))</pre> | `{}` | no |
| <a name="input_ou_id"></a> [ou\_id](#input\_ou\_id) | Organizational Unit ID or name where the Project will be a descendant. | `string` | n/a | yes |
| <a name="input_owner_user_group_ids"></a> [owner\_user\_group\_ids](#input\_owner\_user\_group\_ids) | List of owner user group IDs for the Project. | `list(number)` | n/a | yes |
| <a name="input_owner_user_ids"></a> [owner\_user\_ids](#input\_owner\_user\_ids) | List of owner user IDs for the Project. | `list(number)` | n/a | yes |
| <a name="input_permission_scheme_id"></a> [permission\_scheme\_id](#input\_permission\_scheme\_id) | Permission scheme ID for the Project. | `number` | `3` | no |
| <a name="input_project_alias"></a> [project\_alias](#input\_project\_alias) | Alias of the Project, used as a prefix for resource names. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the Project. | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | Regions where the compliance check applies. | `list(string)` | <pre>[<br>  "us-east-1"<br>]</pre> | no |
| <a name="input_scp_policy"></a> [scp\_policy](#input\_scp\_policy) | The JSON policy document for the Service Control Policy (SCP). | `string` | `null` | no |
| <a name="input_scp_policy_template"></a> [scp\_policy\_template](#input\_scp\_policy\_template) | List of paths to template files for the Service Control Policies (SCPs). | `list(string)` | `[]` | no |
| <a name="input_severity_type_id"></a> [severity\_type\_id](#input\_severity\_type\_id) | The severity type ID. | `number` | `3` | no |
| <a name="input_system_managed_policies"></a> [system\_managed\_policies](#input\_system\_managed\_policies) | List of system managed policies | <pre>list(object({<br>    id                    = number<br>    name                  = string<br>    system_managed_policy = bool<br>  }))</pre> | n/a | yes |
| <a name="input_user_groups"></a> [user\_groups](#input\_user\_groups) | List of user groups to create, with IDMS ID, group name, and app role ID. | <pre>list(object({<br>    idms_id     = number<br>    group_name  = string<br>    app_role_id = number<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_debug_car_policies"></a> [debug\_car\_policies](#output\_debug\_car\_policies) | n/a |
| <a name="output_debug_policy_id_map"></a> [debug\_policy\_id\_map](#output\_debug\_policy\_id\_map) | n/a |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The ID of the created project |
<!-- END_TF_DOCS -->