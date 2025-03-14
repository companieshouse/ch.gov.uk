data "vault_generic_secret" "stack_secrets" {
  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_name}-stack"
}

data "vault_generic_secret" "service_secrets" {
  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_name}-stack/${local.service_name}"
}

data "aws_kms_key" "kms_key" {
  key_id = local.kms_alias
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnets" "application" {
  filter {
    name   = "tag:Name"
    values = [local.application_subnet_pattern]
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "${local.name_prefix}-cluster"
}

data "aws_iam_role" "ecs_cluster_iam_role" {
  name = "${local.name_prefix}-ecs-task-execution-role"
}

data "aws_lb" "chgovuk_lb" {
  name = "${var.environment}-chs-chgovuk"
}

data "aws_lb_listener" "chgovuk_lb_listener" {
  load_balancer_arn = data.aws_lb.chgovuk_lb.arn
  port              = 443
}

data "aws_ssm_parameters_by_path" "secrets" {
  path = "/${local.name_prefix}"
}

data "aws_ssm_parameter" "secret" {
  for_each = toset(data.aws_ssm_parameters_by_path.secrets.names)
  name     = each.key
}

data "aws_ssm_parameters_by_path" "global_secrets" {
  path = "/${local.global_prefix}"
}

data "aws_ssm_parameter" "global_secret" {
  for_each = toset(data.aws_ssm_parameters_by_path.global_secrets.names)
  name     = each.key
}

data "vault_generic_secret" "shared_s3" {
  path = "aws-accounts/shared-services/s3"
}
