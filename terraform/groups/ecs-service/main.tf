provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
  }
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.54.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

module "ecs-service-search" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.293"

  # Environmental configuration
  environment                         = var.environment
  aws_region                          = var.aws_region
  aws_profile                         = var.aws_profile
  vpc_id                              = data.aws_vpc.vpc.id
  ecs_cluster_id                      = data.aws_ecs_cluster.ecs_cluster.id
  task_execution_role_arn             = data.aws_iam_role.ecs_cluster_iam_role.arn

  # Load balancer configuration
  lb_listener_arn                     = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority           = local.lb_listener_rule_priority_search
  lb_listener_paths                   = local.lb_listener_paths_search
  enable_listener                     = var.enable_listener_search

  # ECS Task container health check
  use_task_container_healthcheck      = true
  healthcheck_path                    = local.healthcheck_path
  healthcheck_matcher                 = local.healthcheck_matcher

  # Docker container details
  docker_registry                     = var.docker_registry
  docker_repo                         = local.docker_repo
  container_version                   = var.chgovuk_version
  container_port                      = local.container_port

  # Service configuration
  service_name                        = local.service_name_search
  name_prefix                         = local.name_prefix

  # Service performance and scaling configs
  desired_task_count                  = var.desired_task_count_search
  min_task_count                      = var.min_task_count_search
  max_task_count                      = var.max_task_count_search
  required_cpus                       = var.required_cpus
  required_memory                     = var.required_memory
  service_autoscale_enabled           = var.service_autoscale_enabled
  service_autoscale_target_value_cpu  = var.service_autoscale_target_value_cpu
  service_scaledown_schedule          = var.service_scaledown_schedule
  service_scaleup_schedule            = var.service_scaleup_schedule
  use_capacity_provider               = var.use_capacity_provider
  use_fargate                         = var.use_fargate
  fargate_subnets                     = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment                    = local.task_environment
  task_secrets                        = local.task_secrets
  app_environment_filename            = local.app_environment_filename
  use_set_environment_files           = local.use_set_environment_files
  read_only_root_filesystem           = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus
  eric_memory               = var.eric_memory
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []
}

module "ecs-service-officers" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.293"

  # Environmental configuration
  environment                         = var.environment
  aws_region                          = var.aws_region
  aws_profile                         = var.aws_profile
  vpc_id                              = data.aws_vpc.vpc.id
  ecs_cluster_id                      = data.aws_ecs_cluster.ecs_cluster.id
  task_execution_role_arn             = data.aws_iam_role.ecs_cluster_iam_role.arn

  # Load balancer configuration
  lb_listener_arn                     = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority           = local.lb_listener_rule_priority_officers
  lb_listener_paths                   = local.lb_listener_paths_officers
  enable_listener                     = var.enable_listener_officers

  # ECS Task container health check
  use_task_container_healthcheck      = true
  healthcheck_path                    = local.healthcheck_path
  healthcheck_matcher                 = local.healthcheck_matcher

  # Docker container details
  docker_registry                     = var.docker_registry
  docker_repo                         = local.docker_repo
  container_version                   = var.chgovuk_version
  container_port                      = local.container_port

  # Service configuration
  service_name                        = local.service_name_officers
  name_prefix                         = local.name_prefix

  # Service performance and scaling configs
  desired_task_count                  = var.desired_task_count_officers
  min_task_count                      = var.min_task_count_officers
  max_task_count                      = var.max_task_count_officers
  required_cpus                       = var.required_cpus
  required_memory                     = var.required_memory
  service_autoscale_enabled           = var.service_autoscale_enabled
  service_autoscale_target_value_cpu  = var.service_autoscale_target_value_cpu
  service_scaledown_schedule          = var.service_scaledown_schedule
  service_scaleup_schedule            = var.service_scaleup_schedule
  use_capacity_provider               = var.use_capacity_provider
  use_fargate                         = var.use_fargate
  fargate_subnets                     = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment                    = local.task_environment
  task_secrets                        = local.task_secrets
  app_environment_filename            = local.app_environment_filename
  use_set_environment_files           = local.use_set_environment_files
  read_only_root_filesystem           = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus
  eric_memory               = var.eric_memory
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []
}

module "ecs-service-default" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-service?ref=1.0.293"

  # Environmental configuration
  environment                         = var.environment
  aws_region                          = var.aws_region
  aws_profile                         = var.aws_profile
  vpc_id                              = data.aws_vpc.vpc.id
  ecs_cluster_id                      = data.aws_ecs_cluster.ecs_cluster.id
  task_execution_role_arn             = data.aws_iam_role.ecs_cluster_iam_role.arn

  # Load balancer configuration
  lb_listener_arn                     = data.aws_lb_listener.chgovuk_lb_listener.arn
  lb_listener_rule_priority           = local.lb_listener_rule_priority
  lb_listener_paths                   = local.lb_listener_paths
  enable_listener                     = var.enable_listener

  # ECS Task container health check
  use_task_container_healthcheck      = true
  healthcheck_path                    = local.healthcheck_path
  healthcheck_matcher                 = local.healthcheck_matcher

  # Docker container details
  docker_registry                     = var.docker_registry
  docker_repo                         = local.docker_repo
  container_version                   = var.chgovuk_version
  container_port                      = local.container_port

  # Service configuration
  service_name                        = local.service_name
  name_prefix                         = local.name_prefix

  # Service performance and scaling configs
  desired_task_count                  = var.desired_task_count
  max_task_count                      = var.max_task_count
  required_cpus                       = var.required_cpus
  required_memory                     = var.required_memory
  service_autoscale_enabled           = var.service_autoscale_enabled
  service_autoscale_target_value_cpu  = var.service_autoscale_target_value_cpu
  service_scaledown_schedule          = var.service_scaledown_schedule
  service_scaleup_schedule            = var.service_scaleup_schedule
  use_capacity_provider               = var.use_capacity_provider
  use_fargate                         = var.use_fargate
  fargate_subnets                     = local.application_subnet_ids

  # Cloudwatch
  cloudwatch_alarms_enabled = var.cloudwatch_alarms_enabled

  # Service environment variable and secret configs
  task_environment                    = local.task_environment
  task_secrets                        = local.task_secrets
  app_environment_filename            = local.app_environment_filename
  use_set_environment_files           = local.use_set_environment_files
  read_only_root_filesystem           = false

  # eric options for eric running Web module
  # eric secrets not used in WEB mode, so passing in an empty array
  use_eric_reverse_proxy    = true
  eric_version              = var.eric_version
  eric_cpus                 = var.eric_cpus
  eric_memory               = var.eric_memory
  eric_port                 = local.eric_port
  eric_environment_filename = local.eric_environment_filename
  eric_secrets              = []
}

module "secrets" {
  source      = "git@github.com:companieshouse/terraform-modules//aws/ecs/secrets?ref=1.0.216"

  name_prefix = "${local.service_name}-${var.environment}"
  environment = var.environment
  kms_key_id  = data.aws_kms_key.kms_key.id
  secrets     = nonsensitive(local.service_secrets)
}
