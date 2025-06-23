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

data "aws_ami" "ec2" {
  name_regex  = var.ec2_ami_name_regex
  most_recent = true
  owners      = var.ec2_ami_owners
}

# ------------------------------------------------------------------------------
# Default service ECS cluster data
# ------------------------------------------------------------------------------
data "vault_generic_secret" "stack_secrets_default" {
  count = var.create_ecs_cluster_default ? 1 : 0

  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_fullname_default}"
}

data "aws_ec2_instance_type" "default" {
  instance_type = var.ec2_instance_type_default
}

data "aws_subnets" "stack_application_default" {
  count = var.create_ecs_cluster_default ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_application_subnet_pattern_default]
  }
  filter {
    name   = "tag:NetworkType"
    values = ["private"]
  }
}

data "aws_vpc" "stack_vpc_default" {
  count = var.create_ecs_cluster_default ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_vpc_name_default]
  }
}

data "aws_kms_key" "stack_kms_default" {
  count = var.create_ecs_cluster_default ? 1 : 0

  key_id = "alias/${var.aws_profile}/${local.stack_kms_key_alias_default}"
}

# ------------------------------------------------------------------------------
# Officers service ECS cluster data
# ------------------------------------------------------------------------------
data "vault_generic_secret" "stack_secrets_officers" {
  count = var.create_ecs_cluster_officers ? 1 : 0

  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_fullname_officers}"
}

data "aws_ec2_instance_type" "officers" {
  instance_type = var.ec2_instance_type_officers
}

data "aws_subnets" "stack_application_officers" {
  count = var.create_ecs_cluster_officers ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_application_subnet_pattern_officers]
  }
  filter {
    name   = "tag:NetworkType"
    values = ["private"]
  }
}

data "aws_vpc" "stack_vpc_officers" {
  count = var.create_ecs_cluster_officers ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_vpc_name_officers]
  }
}

data "aws_kms_key" "stack_kms_officers" {
  count = var.create_ecs_cluster_officers ? 1 : 0

  key_id = "alias/${var.aws_profile}/${local.stack_kms_key_alias_officers}"
}

# ------------------------------------------------------------------------------
# Search service ECS cluster data
# ------------------------------------------------------------------------------
data "vault_generic_secret" "stack_secrets_search" {
  count = var.create_ecs_cluster_search ? 1 : 0

  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_fullname_search}"
}

data "aws_ec2_instance_type" "search" {
  instance_type = var.ec2_instance_type_search
}

data "aws_subnets" "stack_application_search" {
  count = var.create_ecs_cluster_search ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_application_subnet_pattern_search]
  }
  filter {
    name   = "tag:NetworkType"
    values = ["private"]
  }
}

data "aws_vpc" "stack_vpc_search" {
  count = var.create_ecs_cluster_search ? 1 : 0

  filter {
    name   = "tag:Name"
    values = [local.stack_vpc_name_search]
  }
}

data "aws_kms_key" "stack_kms_search" {
  count = var.create_ecs_cluster_search ? 1 : 0

  key_id = "alias/${var.aws_profile}/${local.stack_kms_key_alias_search}"
}
