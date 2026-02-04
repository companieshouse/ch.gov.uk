provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.3, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.54.0, < 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0, < 5.0"
    }
  }
  backend "s3" {}
}

# ------------------------------------------------------------------------------
# ECS cluster modules
# ------------------------------------------------------------------------------
module "ecs_cluster_default" {
  count  = var.create_ecs_cluster_default ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-cluster?ref=1.0.366"

  aws_profile = var.aws_profile
  environment = var.environment
  name_prefix = local.stack_name_prefix_default
  stack_name  = local.stack_name_default
  subnet_ids  = local.stack_application_subnet_ids_default
  vpc_id      = local.stack_vpc_id_default

  asg_desired_instance_count = local.asg_desired_instance_count_default
  asg_max_instance_count     = local.asg_max_instance_count_default
  asg_min_instance_count     = local.asg_min_instance_count_default
  ec2_image_id               = local.ec2_ami_id
  ec2_instance_type          = var.ec2_instance_type_default
  ec2_key_pair_name          = var.ec2_key_pair_name
  enable_asg_autoscaling     = true
  scaledown_schedule         = var.asg_scaledown_schedule_default
  scaleup_schedule           = var.asg_scaleup_schedule_default

  enable_container_insights   = true
  notify_topic_slack_endpoint = local.stack_notify_topic_slack_endpoint_default
}

module "cluster_secrets_default" {
  count  = var.create_ecs_cluster_default ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/parameter-store?ref=1.0.366"

  name_prefix = local.stack_name_prefix_default
  secrets     = local.stack_parameter_store_secrets_default
  kms_key_id  = local.stack_kms_key_id_default
}

module "cluster_instance_refresh_default" {
  count  = local.enable_cluster_instance_refresh_default ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/refresh-instances-lambda?ref=1.0.366"

  environment = var.environment
  service     = local.service_name

  ecs_cluster_name                   = module.ecs_cluster_default[0].ecs_cluster_name
  ecs_cluster_capacity_provider_name = module.ecs_cluster_default[0].ecs_cluster_capacity_provider_name
  refresh_schedule_expression        = var.instance_refresh_schedule_default

  lambda_s3_bucket_name = local.s3_release_bucket
  lambda_s3_key         = var.instance_refresh_lambda_s3_key
}

module "ecs_cluster_officers" {
  count  = var.create_ecs_cluster_officers ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-cluster?ref=1.0.366"

  aws_profile = var.aws_profile
  environment = var.environment
  name_prefix = local.stack_name_prefix_officers
  stack_name  = local.stack_name_officers
  subnet_ids  = local.stack_application_subnet_ids_officers
  vpc_id      = local.stack_vpc_id_officers

  asg_desired_instance_count = local.asg_desired_instance_count_officers
  asg_max_instance_count     = local.asg_max_instance_count_officers
  asg_min_instance_count     = local.asg_min_instance_count_officers
  ec2_image_id               = local.ec2_ami_id
  ec2_instance_type          = var.ec2_instance_type_officers
  ec2_key_pair_name          = var.ec2_key_pair_name
  enable_asg_autoscaling     = true
  scaledown_schedule         = var.asg_scaledown_schedule_officers
  scaleup_schedule           = var.asg_scaleup_schedule_officers

  enable_container_insights   = true
  notify_topic_slack_endpoint = local.stack_notify_topic_slack_endpoint_officers
}

module "cluster_secrets_officers" {
  count  = var.create_ecs_cluster_officers ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/parameter-store?ref=1.0.366"

  name_prefix = local.stack_name_prefix_officers
  secrets     = local.stack_parameter_store_secrets_officers
  kms_key_id  = local.stack_kms_key_id_officers
}

module "cluster_instance_refresh_officers" {
  count  = local.enable_cluster_instance_refresh_officers ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/refresh-instances-lambda?ref=1.0.366"

  environment = var.environment
  service     = local.service_name_officers

  ecs_cluster_name                   = module.ecs_cluster_officers[0].ecs_cluster_name
  ecs_cluster_capacity_provider_name = module.ecs_cluster_officers[0].ecs_cluster_capacity_provider_name
  refresh_schedule_expression        = var.instance_refresh_schedule_officers

  lambda_s3_bucket_name = local.s3_release_bucket
  lambda_s3_key         = var.instance_refresh_lambda_s3_key
}

module "ecs_cluster_search" {
  count  = var.create_ecs_cluster_search ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-cluster?ref=1.0.366"

  aws_profile = var.aws_profile
  environment = var.environment
  name_prefix = local.stack_name_prefix_search
  stack_name  = local.stack_name_search
  subnet_ids  = local.stack_application_subnet_ids_search
  vpc_id      = local.stack_vpc_id_search

  asg_desired_instance_count = local.asg_desired_instance_count_search
  asg_max_instance_count     = local.asg_max_instance_count_search
  asg_min_instance_count     = local.asg_min_instance_count_search
  ec2_image_id               = local.ec2_ami_id
  ec2_instance_type          = var.ec2_instance_type_search
  ec2_key_pair_name          = var.ec2_key_pair_name
  enable_asg_autoscaling     = true
  scaledown_schedule         = var.asg_scaledown_schedule_search
  scaleup_schedule           = var.asg_scaleup_schedule_search

  enable_container_insights   = true
  notify_topic_slack_endpoint = local.stack_notify_topic_slack_endpoint_search
}

module "cluster_secrets_search" {
  count  = var.create_ecs_cluster_search ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/parameter-store?ref=1.0.366"

  name_prefix = local.stack_name_prefix_search
  secrets     = local.stack_parameter_store_secrets_search
  kms_key_id  = local.stack_kms_key_id_search
}

module "cluster_instance_refresh_search" {
  count  = local.enable_cluster_instance_refresh_search ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/refresh-instances-lambda?ref=1.0.366"

  environment = var.environment
  service     = local.service_name_search

  ecs_cluster_name                   = module.ecs_cluster_search[0].ecs_cluster_name
  ecs_cluster_capacity_provider_name = module.ecs_cluster_search[0].ecs_cluster_capacity_provider_name
  refresh_schedule_expression        = var.instance_refresh_schedule_search

  lambda_s3_bucket_name = local.s3_release_bucket
  lambda_s3_key         = var.instance_refresh_lambda_s3_key
}

# ------------------------------------------------------------------------------
# Search ECS service modules
# ------------------------------------------------------------------------------
module "ecs-service-search" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.304"

  # Environmental configuration
  environment             = var.environment
  aws_region              = var.aws_region
  aws_profile             = var.aws_profile
  vpc_id                  = data.aws_vpc.vpc.id
  ecs_cluster_id          = local.ecs_cluster_id_search
  task_execution_role_arn = local.task_execution_role_arn_search

  # Load balancer configuration
  lb_listener_arn           = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority = local.lb_listener_rule_priority_search
  lb_listener_paths         = local.lb_listener_paths_search

  # ECS Task container health check
  use_task_container_healthcheck = var.use_task_container_healthcheck_search
  healthcheck_path               = local.healthcheck_path
  healthcheck_matcher            = local.healthcheck_matcher

  # Docker container details
  docker_registry   = var.docker_registry
  docker_repo       = local.docker_repo
  container_version = var.chgovuk_version
  container_port    = local.container_port

  # Service configuration
  service_name = local.service_name_search
  name_prefix  = local.name_prefix_search

  # Service performance and scaling configs
  desired_task_count                   = var.desired_task_count_search
  min_task_count                       = var.min_task_count_search
  max_task_count                       = var.max_task_count_search
  required_cpus                        = var.required_cpus_search
  required_memory                      = var.required_memory_search
  service_autoscale_enabled            = var.service_autoscale_enabled
  service_autoscale_target_value_cpu   = var.service_autoscale_target_value_cpu
  service_autoscale_scale_in_cooldown  = var.service_autoscale_scale_in_cooldown
  service_autoscale_scale_out_cooldown = var.service_autoscale_scale_out_cooldown
  service_scaledown_schedule           = var.service_scaledown_schedule
  service_scaleup_schedule             = var.service_scaleup_schedule
  use_capacity_provider                = var.use_capacity_provider
  use_fargate                          = var.use_fargate_search
  fargate_subnets                      = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment          = local.task_environment_search
  task_secrets              = local.task_secrets_search
  app_environment_filename  = local.app_environment_filename
  use_set_environment_files = local.use_set_environment_files
  read_only_root_filesystem = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus_search
  eric_memory               = var.eric_memory_search
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []

  create_service_dashboard = var.create_service_dashboard_search
}

module "secrets_search" {
  count  = var.use_ecs_cluster_search && var.create_ecs_cluster_search ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.333"

  name_prefix = "${local.service_name_search}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.service_secrets_search)
}

# ------------------------------------------------------------------------------
# Officers ECS service modules
# ------------------------------------------------------------------------------
module "ecs-service-officers" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.304"

  # Environmental configuration
  environment             = var.environment
  aws_region              = var.aws_region
  aws_profile             = var.aws_profile
  vpc_id                  = data.aws_vpc.vpc.id
  ecs_cluster_id          = local.ecs_cluster_id_officers
  task_execution_role_arn = local.task_execution_role_arn_officers

  # Load balancer configuration
  lb_listener_arn           = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority = local.lb_listener_rule_priority_officers
  lb_listener_paths         = local.lb_listener_paths_officers

  # ECS Task container health check
  use_task_container_healthcheck = var.use_task_container_healthcheck_officers
  healthcheck_path               = local.healthcheck_path
  healthcheck_matcher            = local.healthcheck_matcher

  # Docker container details
  docker_registry   = var.docker_registry
  docker_repo       = local.docker_repo
  container_version = var.chgovuk_version
  container_port    = local.container_port

  # Service configuration
  service_name = local.service_name_officers
  name_prefix  = local.name_prefix_officers

  # Service performance and scaling configs
  desired_task_count                   = var.desired_task_count_officers
  min_task_count                       = var.min_task_count_officers
  max_task_count                       = var.max_task_count_officers
  required_cpus                        = var.required_cpus_officers
  required_memory                      = var.required_memory_officers
  service_autoscale_enabled            = var.service_autoscale_enabled
  service_autoscale_target_value_cpu   = var.service_autoscale_target_value_cpu
  service_autoscale_scale_in_cooldown  = var.service_autoscale_scale_in_cooldown
  service_autoscale_scale_out_cooldown = var.service_autoscale_scale_out_cooldown
  service_scaledown_schedule           = var.service_scaledown_schedule
  service_scaleup_schedule             = var.service_scaleup_schedule
  use_capacity_provider                = var.use_capacity_provider
  use_fargate                          = var.use_fargate_officers
  fargate_subnets                      = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment          = local.task_environment_officers
  task_secrets              = local.task_secrets_officers
  app_environment_filename  = local.app_environment_filename
  use_set_environment_files = local.use_set_environment_files
  read_only_root_filesystem = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus_officers
  eric_memory               = var.eric_memory_officers
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []

  create_service_dashboard = var.create_service_dashboard_officers
}

module "secrets_officers" {
  count  = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.333"

  name_prefix = "${local.service_name_officers}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.service_secrets_officers)
}

# ------------------------------------------------------------------------------
# Default ECS service modules
# ------------------------------------------------------------------------------
module "ecs-service-default" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.304"

  # Environmental configuration
  environment             = var.environment
  aws_region              = var.aws_region
  aws_profile             = var.aws_profile
  vpc_id                  = data.aws_vpc.vpc.id
  ecs_cluster_id          = local.ecs_cluster_id_default
  task_execution_role_arn = local.task_execution_role_arn_default

  # Load balancer configuration
  lb_listener_arn           = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority = local.lb_listener_rule_priority
  lb_listener_paths         = local.lb_listener_paths

  # ECS Task container health check
  use_task_container_healthcheck = var.use_task_container_healthcheck
  healthcheck_path               = local.healthcheck_path
  healthcheck_matcher            = local.healthcheck_matcher

  # Docker container details
  docker_registry   = var.docker_registry
  docker_repo       = local.docker_repo
  container_version = var.chgovuk_version
  container_port    = local.container_port

  # Service configuration
  service_name = local.service_name
  name_prefix  = local.name_prefix_default

  # Service performance and scaling configs
  desired_task_count                   = var.desired_task_count
  max_task_count                       = var.max_task_count
  min_task_count                       = var.min_task_count
  required_cpus                        = local.task_required_cpu_default
  required_memory                      = local.task_required_mem_default
  service_autoscale_enabled            = var.service_autoscale_enabled
  service_autoscale_target_value_cpu   = var.service_autoscale_target_value_cpu
  service_autoscale_scale_in_cooldown  = var.service_autoscale_scale_in_cooldown
  service_autoscale_scale_out_cooldown = var.service_autoscale_scale_out_cooldown
  service_scaledown_schedule           = var.service_scaledown_schedule
  service_scaleup_schedule             = var.service_scaleup_schedule
  use_capacity_provider                = var.use_capacity_provider
  use_fargate                          = var.use_fargate
  fargate_subnets                      = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment          = local.task_environment
  task_secrets              = local.task_secrets_default
  app_environment_filename  = local.app_environment_filename
  use_set_environment_files = local.use_set_environment_files
  read_only_root_filesystem = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus
  eric_memory               = var.eric_memory
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []

  create_service_dashboard = var.create_service_dashboard
}

module "secrets_default" {
  count  = var.use_ecs_cluster_default && var.create_ecs_cluster_default ? 1 : 0
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.333"

  name_prefix = "${local.service_name}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.service_secrets_default)
}

# ------------------------------------------------------------------------------
# Shared service modules
# ------------------------------------------------------------------------------
module "secrets" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.333"

  name_prefix = "${local.service_name}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.service_secrets)
}
