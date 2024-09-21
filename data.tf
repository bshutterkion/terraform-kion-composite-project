data "kion_aws_iam_policy" "system_managed" {
  for_each = { for policy in local.car_policies : policy.key => policy if policy.type == "system_managed" }
  filter {
    name   = "name"
    values = [each.value.name]
  }
}
