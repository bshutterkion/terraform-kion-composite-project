output "project_id" {
  description = "The ID of the created project"
  value       = module.project.project_id
}

output "debug_policy_id_map" {
  value = local.policy_id_map
}

output "debug_car_policies" {
  value = {
    for car_name, car in var.cloud_access_roles : car_name => {
      user_managed   = [for policy in car.aws_iam_policies.user_managed : replace(basename(policy.template), "\\.(tpl|json|ya?ml)$", "")]
      system_managed = car.aws_iam_policies.system_managed
    }
  }
}
