locals {

  # Update cloud_rule_policies with sanitized names
  cloud_rule_policies = flatten([
    for cr in var.cloud_rules : concat(
      [
        # Process user-managed policies
        for policy in try(cr.cloud_rule_attachments.aws_iam_policies.user_managed, []) : {
          name            = replace(basename(policy.template), "\\.(tpl|json|ya?ml)$", "")
          policy_template = policy.template
          type            = "user_managed"
          cloud_rule_name = cr.name
          key             = replace(basename(policy.template), "\\.(tpl|json|ya?ml)$", "")
        }
      ],
      [
        # Process system-managed policies
        for policy in try(cr.cloud_rule_attachments.aws_iam_policies.system_managed, []) : {
          name            = policy
          policy_template = null
          type            = "system_managed"
          cloud_rule_name = cr.name
          key             = policy
        }
      ]
    )
  ])

  # Update car_policies with sanitized names
  car_policies = flatten([
    for car in var.cloud_access_roles : concat(
      [
        for policy in try(car.aws_iam_policies.user_managed, []) : {
          name            = basename(policy.template)
          policy_template = policy.template
          type            = "user_managed"
          car_name        = car.name
          key             = "car-${var.project_alias}-${car.name}-${index(car.aws_iam_policies.user_managed, policy)}"
        }
      ],
      [
        for policy in try(car.aws_iam_policies.system_managed, []) : {
          name            = policy
          policy_template = null
          type            = "system_managed"
          car_name        = car.name
          key             = "car-${var.project_alias}-${car.name}-${policy}"
        }
      ]
    )
  ])


  # Combine all policies
  all_policies = concat(
    local.cloud_rule_policies,
    [for policy in local.car_policies : policy if policy.type == "user_managed"]
  )

  policy_id_map = merge(
    {
      for policy in local.all_policies : policy.key =>
      policy.type == "user_managed"
      ? module.iam_policies[policy.key].policy_id
      : null # This should never happen for all_policies, but we'll keep it as a safeguard
    },
    {
      for policy in local.car_policies : policy.key =>
      policy.type == "system_managed"
      ? try(
        [for p in var.system_managed_policies : p.id if p.name == policy.name][0],
        null # Return null if no matching policy is found
      )
      : module.iam_policies[policy.key].policy_id
    }
  )

  # Consolidate SCP templates
  scp_templates = distinct(flatten([
    for cr in var.cloud_rules : try(cr.cloud_rule_attachments.scps, [])
  ]))

  scp_map = {
    for scp_template in local.scp_templates :
    scp_template => {
      name         = "${var.project_alias}-SCP-${replace(replace(basename(scp_template), ".tpl", ""), "[^a-zA-Z0-9]", "")}"
      scp_template = scp_template
    }
  }

  user_group_name_to_id = {
    for group in var.user_groups :
    group.group_name => module.user_groups[group.group_name].user_group_id
  }

  cloud_provider_id_map = {
    "AWS"   = 1
    "Azure" = 2
    "GCP"   = 3
  }

  compliance_check_type_map = {
    "External"        = 1
    "Cloud Custodian" = 2
  }

  frequency_type_map = {
    "Minutes" = 2
    "Hours"   = 3
    "Days"    = 4
  }

  severity_type_map = {
    "Informational" = 1
    "Low"           = 2
    "Medium"        = 3
    "High"          = 4
    "Critical"      = 5
  }

  all_checks = flatten([
    for check_type in ["user_managed", "system_managed"] : [
      for check in try(var.cloud_rule_attachments.compliance_standard.compliance_checks[check_type], []) : {
        template        = check.template
        is_system_check = check_type == "system_managed"
        overrides = merge({
          regions               = null
          auto_archive          = null
          all_regions           = null
          severity              = null
          frequency             = null
          frequency_type        = null
          compliance_check_type = null
          csp                   = null
        }, check.overrides)
      }
    ]
  ])

  has_compliance_checks = length(local.all_checks) > 0

  # Process compliance standards and checks
  compliance_data = flatten([
    # Process compliance standards defined at the top level
    can(var.compliance_standards) ? [
      for cs in var.compliance_standards : {
        name        = cs.name
        description = cs.description
        checks = flatten([
          # User-managed checks
          can(cs.compliance_checks.user_managed) ? [
            for check in try(cs.compliance_checks.user_managed, []) : {
              template                 = check.template
              overrides                = check.overrides
              is_system_check          = false
              compliance_standard_name = "${cs.name}"
              key                      = "${cs.name}-${replace(replace(basename(check.template), ".tpl", ""), "[^a-zA-Z0-9]", "")}"
            }
          ] : [],
          # System-managed checks
          can(cs.compliance_checks.system_managed) ? [
            for check in try(cs.compliance_checks.system_managed, []) : {
              template                 = check.template
              overrides                = try(check.overrides, {})
              is_system_check          = true
              compliance_standard_name = "${cs.name}"
              key                      = "${cs.name}-${replace(replace(check.template, " ", ""), "[^a-zA-Z0-9]", "")}"
            }
          ] : []
        ])
      }
    ] : [],
    # Process compliance standards attached to cloud rules
    flatten([
      for cr in var.cloud_rules :
      can(cr.cloud_rule_attachments.compliance_standards) ? [
        for cs_name in cr.cloud_rule_attachments.compliance_standards : {
          name   = cs_name
          checks = [] # No checks defined at this level
        }
      ] : []
    ])
  ])

  # Deduplicate compliance standards
  unique_compliance_standards = {
    for cs in local.compliance_data : cs.name => cs...
  }

  # Flatten all compliance checks
  compliance_checks = flatten([
    for standard in local.compliance_data : standard.checks
  ])

  # Create a map of compliance standards
  compliance_standards = {
    for standard in local.compliance_data :
    standard.name => {
      name        = "${standard.name}"
      description = try(standard.description, null)
      checks      = try(standard.checks, [])
    }
  }
  valid_user_or_group = length(var.owner_user_group_ids) > 0 || length(var.owner_user_ids) > 0

  all_user_groups = flatten([
    for group in var.user_groups : {
      id          = local.user_group_name_to_id[group.group_name]
      app_role_id = group.app_role_id
    }
  ])

  user_groups_by_role = {
    for app_role_id in distinct([for group in local.all_user_groups : group.app_role_id]) :
    app_role_id => [
      for group in local.all_user_groups : group.id
      if group.app_role_id == app_role_id
    ]
  }
  remove_extensions = [".tpl", ".json", ".yaml", ".yml"]
}

locals {
  compliance_check_ids_by_standard = {
    for cs_name in distinct([for check in local.compliance_checks : check.compliance_standard_name]) :
    cs_name => compact([
      for check in local.compliance_checks :
      check.compliance_standard_name == cs_name ?
      module.compliance_checks[check.key].compliance_check_id : null
    ])
  }

  # Create a map for CloudFormation templates
  cloudformation_template_map = {
    for cft in try(var.cloudformation_templates, []) :
    cft.name => cft
  }

  # Create an ID map for CloudFormation templates
  cloudformation_template_id_map = {
    for name, cft in module.cloudformation_templates :
    name => cft.cloudformation_template_id
  }

}
