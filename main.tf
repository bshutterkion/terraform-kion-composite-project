locals {
  ou_id_is_number = can(tonumber(var.ou_id))
  ou_id_lookup = local.ou_id_is_number ? {} : {
    ou_name = var.ou_id
  }
}

data "kion_ou" "project_ou" {
  filter {
    name   = "name"
    values = [var.ou_id]
  }
}

module "project" {
  source = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project"

  name                 = var.project_name
  description          = var.description
  ou_id                = one(data.kion_ou.project_ou.list[*].id)
  owner_user_group_ids = var.owner_user_group_ids
  permission_scheme_id = var.permission_scheme_id
  labels               = { for k, v in var.labels : k => v.value }
}

module "user_groups" {
  source       = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/user-group"
  for_each     = { for group in var.user_groups : group.group_name => group }
  name         = "${var.project_alias} ${each.value.group_name}"
  description  = "${var.project_name} ${each.value.group_name} User Group"
  idms_id      = each.value.idms_id
  owner_users  = [for id in var.owner_user_ids : { id = id }]
  owner_groups = [for id in var.owner_user_group_ids : { id = id }]
  users        = []
  depends_on   = [module.project]
}

module "compliance_checks" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/compliance-check"
  for_each = { for check in local.compliance_checks : check.key => check }
  name = each.value.is_system_check ? "${each.value.template}" : coalesce(
    compact([
      for ext in local.remove_extensions : (
        endswith(basename(each.value.template), ext)
        ? substr(basename(each.value.template), 0, length(basename(each.value.template)) - length(ext))
        : null
      )
    ])[0],
    basename(each.value.template)
  )
  cloud_provider_id        = try(local.cloud_provider_id_map[each.value.overrides.csp], 1)
  compliance_check_type_id = try(local.compliance_check_type_map[each.value.overrides.compliance_check_type], 2)
  body_template            = each.value.is_system_check ? null : each.value.template
  owner_users              = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups        = [for id in var.owner_user_group_ids : { id = id }]
  is_system_check          = each.value.is_system_check
  created_by_user_id       = var.owner_user_ids[0]
  compliance_standard_name = each.value.compliance_standard_name
  frequency_minutes        = try(each.value.overrides.frequency, 60)
  frequency_type_id        = try(local.frequency_type_map[each.value.overrides.frequency_type], 2)
  is_all_regions           = try(each.value.overrides.all_regions, true)
  is_auto_archived         = try(each.value.overrides.auto_archive, true)
  regions                  = try(each.value.overrides.regions, ["us-east-1"])
  severity_type_id         = try(each.value.overrides.severity_type_id, 3)
}

module "compliance_standards" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/compliance-standard"
  for_each = local.compliance_standards

  name               = each.value.name
  description        = each.value.description
  created_by_user_id = var.owner_user_ids[0]
  owner_users        = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups  = [for id in var.owner_user_group_ids : { id = id }]
  compliance_checks = [
    for check in each.value.checks :
    { id = module.compliance_checks[check.key].compliance_check_id }
  ]
}

module "iam_policies" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-iam-policy"
  for_each = { for policy in local.all_policies : policy.key => policy if policy.type == "user_managed" }

  name = coalesce(
    compact([
      for ext in local.remove_extensions : (
        endswith(each.value.name, ext)
        ? substr(each.value.name, 0, length(each.value.name) - length(ext))
        : null
      )
    ])[0],
    each.value.name
  )
  policy_template         = each.value.policy_template
  policy_type             = each.value.type
  owner_users             = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups       = [for id in var.owner_user_group_ids : { id = id }]
  system_managed_policies = var.system_managed_policies
}

module "scps" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-service-control-policy"
  for_each = local.scp_map
  name = "SCP-${coalesce(
    compact([
      for ext in local.remove_extensions : (
        endswith(basename(each.value), ext)
        ? substr(basename(each.value), 0, length(basename(each.value)) - length(ext))
        : null
      )
    ])[0],
    basename(each.value)
  )}"
  scp_policy_template = each.value
  description         = "SCP for ${var.project_alias}: ${basename(each.value)}"
  owner_users         = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups   = [for id in var.owner_user_group_ids : { id = id }]
  project_alias       = var.project_alias
}

module "cloudformation_templates" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/aws-cloudformation-template"
  for_each = local.cloudformation_template_map

  name                   = each.value.name
  regions                = try(each.value.regions, ["*"]) // Default to all regions if not specified
  owner_users            = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups      = [for id in var.owner_user_group_ids : { id = id }]
  description            = each.value.description
  policy                 = each.value.policy
  policy_template        = each.value.policy_template
  region                 = try(each.value.region, null)
  sns_arns               = try(each.value.sns_arns, null)
  template_parameters    = try(each.value.template_parameters, null)
  termination_protection = try(each.value.termination_protection, false)
  tags                   = try(each.value.tags, {})
}

module "cloud_rules" {
  source = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/cloud-rule"

  for_each          = { for cr in var.cloud_rules : cr.name => cr }
  name              = each.value.name
  description       = each.value.description
  owner_users       = [for id in var.owner_user_ids : { id = id }]
  owner_user_groups = [for id in var.owner_user_group_ids : { id = id }]
  projects          = [{ id = module.project.project_id }]

  service_control_policies = [
    for scp in try(each.value.cloud_rule_attachments.scps, []) : { id = module.scps[scp].scp_id }
  ]

  aws_iam_policies = flatten([
    # Process user-managed policies
    [
      for policy in try(each.value.cloud_rule_attachments.aws_iam_policies.user_managed, []) : {
        id = module.iam_policies[replace(basename(policy.template), "\\.(tpl|json|ya?ml)$", "")].policy_id
      }
    ],
    # Process system-managed policies
    [
      for policy in try(each.value.cloud_rule_attachments.aws_iam_policies.system_managed, []) : {
        id = local.policy_id_map[policy]
      }
    ]
  ])

  compliance_standards = [
    for cs in try(each.value.cloud_rule_attachments.compliance_standards, []) : {
      id = module.compliance_standards[cs].compliance_standard_id
    }
  ]

  aws_cloudformation_templates = [
    for cft in try(each.value.cloud_rule_attachments.cloudformation_templates, []) : {
      id = try(local.cloudformation_template_id_map[cft], null)
    }
    if can(local.cloudformation_template_id_map[cft])
  ]

  depends_on = [module.compliance_standards, module.project, module.scps, module.iam_policies]
}

module "project_cars" {
  source   = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project-cloud-access-role"
  for_each = { for car in var.cloud_access_roles : car.name => car }

  name                   = each.value.name
  project_id             = module.project.project_id
  aws_iam_role_name      = each.value.aws_iam_role_name
  web_access             = try(each.value.web_access, true)
  short_term_access_keys = try(each.value.short_term_access_keys, true)
  long_term_access_keys  = try(each.value.long_term_access_keys, false)
  future_accounts        = try(each.value.future_accounts, true)
  apply_to_all_accounts  = try(each.value.apply_to_all_accounts, true)

  aws_iam_policies = [
    for policy in local.car_policies :
    { id = local.policy_id_map[policy.key] }
    if policy.car_name == each.value.name
  ]

  user_groups = distinct(concat(
    [for group_name in each.value.user_groups : { id = try(local.user_group_name_to_id[group_name], null) }],
    [for id in var.owner_user_group_ids : { id = id }]
  ))

  users = [for user_id in each.value.users : { id = user_id }]

  depends_on = [module.project, module.iam_policies, module.user_groups]
}

module "project_permission_mapping" {
  source = "/Users/bshutter/Dev/code/kion/bshutter/github/bshutterkion/kion-modules/project-permission-mapping"

  project_id = module.project.project_id

  permission_mappings = [
    for app_role_id, group_ids in local.user_groups_by_role : {
      app_role_id    = app_role_id
      user_group_ids = toset(group_ids)
      user_ids       = []
    }
  ]

  depends_on = [module.project, module.user_groups]
}

