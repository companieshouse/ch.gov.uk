# Define all hardcoded local variable and local variables looked up from data resources
locals {
  stack_name            = "public-data" # this must match the stack name the service deploys into
  name_prefix           = "${local.stack_name}-${var.environment}"
  global_prefix         = "global-${var.environment}"
  service_name          = "ch-gov-uk"
  service_name_search   = "ch-gov-uk-search"
  service_name_officers = "ch-gov-uk-officers"
  container_port        = "10000"
  eric_port             = "10001"
  docker_repo           = "ch.gov.uk"
  kms_alias             = "alias/${var.aws_profile}/environment-services-kms"

  lb_listener_rule_priority          = 1000 # fallback/default service needs high number (10,000 after library multiplier logic)
  lb_listener_rule_priority_search   = 2    # search service gets high usage so use low number for quicker rule evaluation (priority 1 already taken)
  lb_listener_rule_priority_officers = 3    # officers service gets high usage so use low number for quicker rule evaluation

  lb_listener_paths          = var.enable_listener ? ["*"] : ["/DISABLED-*"]
  lb_listener_paths_search   = var.enable_listener_search ? ["/search", "/search/*"] : ["/DISABLED-search*"]
  lb_listener_paths_officers = var.enable_listener_officers ? ["/company/*/officers*", "/officers*"] : ["/DISABLED-officers"]

  healthcheck_path           = "/healthcheck"
  healthcheck_matcher        = "200"
  s3_config_bucket           = data.vault_generic_secret.shared_s3.data["config_bucket_name"]
  app_environment_filename   = "ch.gov.uk.env"
  use_set_environment_files  = var.use_set_environment_files
  application_subnet_ids     = data.aws_subnets.application.ids
  application_subnet_pattern = local.stack_secrets["application_subnet_pattern"]

  stack_secrets   = jsondecode(data.vault_generic_secret.stack_secrets.data_json)
  service_secrets = jsondecode(data.vault_generic_secret.service_secrets.data_json)

  vpc_name = local.stack_secrets["vpc_name"]

  # create a map of secret name => secret arn to pass into ecs service module
  # using the trimprefix function to remove the prefixed path from the secret name
  secrets_arn_map = {
    for sec in data.aws_ssm_parameter.secret :
    trimprefix(sec.name, "/${local.name_prefix}/") => sec.arn
  }

  global_secrets_arn_map = {
    for sec in data.aws_ssm_parameter.global_secret :
    trimprefix(sec.name, "/${local.global_prefix}/") => sec.arn
  }

  global_secret_list = flatten([for key, value in local.global_secrets_arn_map :
    { "name" = upper(key), "valueFrom" = value }
  ])

  ssm_global_version_map = [
    for sec in data.aws_ssm_parameter.global_secret : {
      name = "GLOBAL_${var.ssm_version_prefix}${replace(upper(basename(sec.name)), "-", "_")}", value = sec.version
    }
  ]

  service_secrets_arn_map = {
    for sec in module.secrets.secrets :
    trimprefix(sec.name, "/${local.service_name}-${var.environment}/") => sec.arn
  }

  service_secret_list = flatten([for key, value in local.service_secrets_arn_map :
    { "name" = upper(key), "valueFrom" = value }
  ])

  ssm_service_version_map = [
    for sec in module.secrets.secrets : {
      name = "${replace(upper(local.service_name), "-", "_")}_${var.ssm_version_prefix}${replace(upper(basename(sec.name)), "-", "_")}", value = sec.version
    }
  ]

  task_secrets = concat(local.global_secret_list, local.service_secret_list, [])

  task_required_cpu_default = var.use_ecs_cluster_default && var.create_ecs_cluster_default && !var.use_fargate ? local.ec2_task_cpu_default : var.required_cpus
  task_required_mem_default = var.use_ecs_cluster_default && var.create_ecs_cluster_default && !var.use_fargate ? local.ec2_task_mem_default : var.required_memory
  task_required_memory_kb   = var.required_memory * 1024
  task_environment          = concat(local.ssm_global_version_map, local.ssm_service_version_map, [
    { "name" : "MAX_MEMORY_USAGE", "value" : "${local.task_required_memory_kb}" },
    { "name" : "PORT", "value" : "${local.container_port}" },
    { "name" : "SHARED_MEMORY_PERCENTAGE", "value" : "100" }
  ])

  task_required_cpu_officers       = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers && !var.use_fargate_officers ? local.ec2_task_cpu_officers : var.required_cpus_officers
  task_required_mem_officers       = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers && !var.use_fargate_officers ? local.ec2_task_mem_officers : var.required_memory_officers
  task_required_memory_kb_officers = var.required_memory_officers * 1024
  task_environment_officers        = concat(local.ssm_global_version_map, local.ssm_service_version_map, [
    { "name" : "MAX_MEMORY_USAGE", "value" : "${local.task_required_memory_kb_officers}" },
    { "name" : "PORT", "value" : "${local.container_port}" },
    { "name" : "SHARED_MEMORY_PERCENTAGE", "value" : "100" }
  ])

  task_required_cpu_search       = var.use_ecs_cluster_search && var.create_ecs_cluster_search && !var.use_fargate_search ? local.ec2_task_cpu_search : var.required_cpus_search
  task_required_mem_search       = var.use_ecs_cluster_search && var.create_ecs_cluster_search && !var.use_fargate_search ? local.ec2_task_mem_search : var.required_memory_search
  task_required_memory_kb_search = var.required_memory_search * 1024
  task_environment_search        = concat(local.ssm_global_version_map, local.ssm_service_version_map, [
    { "name" : "MAX_MEMORY_USAGE", "value" : "${local.task_required_memory_kb_search}" },
    { "name" : "PORT", "value" : "${local.container_port}" },
    { "name" : "SHARED_MEMORY_PERCENTAGE", "value" : "100" }
  ])

  eric_environment_filename = "eric-web.env"

  # ------------------------------------------------------------------------------
  # Common ECS cluster locals
  # ------------------------------------------------------------------------------
  ec2_ami_id = var.ec2_ami_id == "" ? data.aws_ami.ec2.id : var.ec2_ami_id

  ec2_os_reserved_cpu = 128
  ec2_os_reserved_mem = 512

  # ------------------------------------------------------------------------------
  # Default service ECS cluster locals
  # ------------------------------------------------------------------------------
  stack_name_default        = local.service_name
  stack_name_prefix_default = "${local.stack_name_default}-${var.environment}"
  stack_fullname_default    = "${local.stack_name_default}-stack"

  stack_secrets_default = var.create_ecs_cluster_default ? jsondecode(data.vault_generic_secret.stack_secrets_default[0].data_json) : {}

  stack_application_subnet_pattern_default  = var.create_ecs_cluster_default ? local.stack_secrets_default["application_subnet_pattern"] : ""
  stack_application_subnet_ids_default      = var.create_ecs_cluster_default ? join(",", data.aws_subnets.stack_application_default[0].ids) : ""
  stack_kms_key_alias_default               = var.create_ecs_cluster_default ? local.stack_secrets_default["kms_key_alias"] : ""
  stack_kms_key_id_default                  = var.create_ecs_cluster_default ? data.aws_kms_key.stack_kms_default[0].id : ""
  stack_notify_topic_slack_endpoint_default = var.create_ecs_cluster_default ? local.stack_secrets_default["notify_topic_slack_endpoint"] : ""
  stack_vpc_name_default                    = var.create_ecs_cluster_default ? local.stack_secrets_default["vpc_name"] : ""
  stack_vpc_id_default                      = var.create_ecs_cluster_default ? data.aws_vpc.stack_vpc_default[0].id : ""

  stack_parameter_store_secrets_default = var.create_ecs_cluster_default ? {
    "web-oauth2-client-id"     = local.stack_secrets_default["web_oauth2_client_id"],
    "web-oauth2-client-secret" = local.stack_secrets_default["web_oauth2_client_secret"],
    "web-oauth2-cookie-secret" = local.stack_secrets_default["web_oauth2_cookie_secret"],
    "web-oauth2-request-key"   = local.stack_secrets_default["web_oauth2_request_key"]
  } : {}

  asg_desired_instance_count_default = var.desired_task_count
  asg_max_instance_count_default     = var.max_task_count * 2
  asg_min_instance_count_default     = 0

  ecs_cluster_id_default          = var.use_ecs_cluster_default && var.create_ecs_cluster_default ? module.ecs_cluster_default[0].ecs_cluster_id : data.aws_ecs_cluster.ecs_cluster.id
  name_prefix_default             = var.use_ecs_cluster_default && var.create_ecs_cluster_default ? local.stack_name_prefix_default : local.name_prefix
  task_execution_role_arn_default = var.use_ecs_cluster_default && var.create_ecs_cluster_default ? module.ecs_cluster_default[0].ecs_task_execution_role_arn : data.aws_iam_role.ecs_cluster_iam_role.arn

  ec2_total_cpu_default = data.aws_ec2_instance_type.default.default_vcpus * 1024
  ec2_task_cpu_default  = local.ec2_total_cpu_default - (local.ec2_os_reserved_cpu + var.eric_cpus)
  ec2_total_mem_default = data.aws_ec2_instance_type.default.memory_size
  ec2_task_mem_default  = local.ec2_total_mem_default - (local.ec2_os_reserved_mem + var.eric_memory)

  # ------------------------------------------------------------------------------
  # Officers service ECS cluster locals
  # ------------------------------------------------------------------------------
  stack_name_officers        = local.service_name_officers
  stack_name_prefix_officers = "${local.stack_name_officers}-${var.environment}"
  stack_fullname_officers    = "${local.stack_name_officers}-stack"

  stack_secrets_officers = var.create_ecs_cluster_officers ? jsondecode(data.vault_generic_secret.stack_secrets_officers[0].data_json) : {}

  stack_application_subnet_pattern_officers  = var.create_ecs_cluster_officers ? local.stack_secrets_officers["application_subnet_pattern"] : ""
  stack_application_subnet_ids_officers      = var.create_ecs_cluster_officers ? join(",", data.aws_subnets.stack_application_officers[0].ids) : ""
  stack_kms_key_alias_officers               = var.create_ecs_cluster_officers ? local.stack_secrets_officers["kms_key_alias"] : ""
  stack_kms_key_id_officers                  = var.create_ecs_cluster_officers ? data.aws_kms_key.stack_kms_officers[0].id : ""
  stack_notify_topic_slack_endpoint_officers = var.create_ecs_cluster_officers ? local.stack_secrets_officers["notify_topic_slack_endpoint"] : ""
  stack_vpc_name_officers                    = var.create_ecs_cluster_officers ? local.stack_secrets_officers["vpc_name"] : ""
  stack_vpc_id_officers                      = var.create_ecs_cluster_officers ? data.aws_vpc.stack_vpc_officers[0].id : ""

  stack_parameter_store_secrets_officers = var.create_ecs_cluster_officers ? {
    "web-oauth2-client-id"     = local.stack_secrets_officers["web_oauth2_client_id"],
    "web-oauth2-client-secret" = local.stack_secrets_officers["web_oauth2_client_secret"],
    "web-oauth2-cookie-secret" = local.stack_secrets_officers["web_oauth2_cookie_secret"],
    "web-oauth2-request-key"   = local.stack_secrets_officers["web_oauth2_request_key"]
  } : {}

  asg_desired_instance_count_officers = var.desired_task_count_officers
  asg_max_instance_count_officers     = var.max_task_count_officers * 2
  asg_min_instance_count_officers     = 0

  ecs_cluster_id_officers          = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers ? module.ecs_cluster_officers[0].ecs_cluster_id : data.aws_ecs_cluster.ecs_cluster.id
  name_prefix_officers             = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers ? local.stack_name_prefix_officers : local.name_prefix
  task_execution_role_arn_officers = var.use_ecs_cluster_officers && var.create_ecs_cluster_officers ? module.ecs_cluster_officers[0].ecs_task_execution_role_arn : data.aws_iam_role.ecs_cluster_iam_role.arn

  ec2_total_cpu_officers = data.aws_ec2_instance_type.officers.default_vcpus * 1024
  ec2_task_cpu_officers  = local.ec2_total_cpu_officers - (local.ec2_os_reserved_cpu + var.eric_cpus_officers)
  ec2_total_mem_officers = data.aws_ec2_instance_type.officers.memory_size
  ec2_task_mem_officers  = local.ec2_total_mem_officers - (local.ec2_os_reserved_mem + var.eric_memory_officers)

  # ------------------------------------------------------------------------------
  # Search service ECS cluster locals
  # ------------------------------------------------------------------------------
  stack_name_search        = local.service_name_search
  stack_name_prefix_search = "${local.stack_name_search}-${var.environment}"
  stack_fullname_search    = "${local.stack_name_search}-stack"

  stack_secrets_search = var.create_ecs_cluster_search ? jsondecode(data.vault_generic_secret.stack_secrets_search[0].data_json) : {}

  stack_application_subnet_pattern_search  = var.create_ecs_cluster_search ? local.stack_secrets_search["application_subnet_pattern"] : ""
  stack_application_subnet_ids_search      = var.create_ecs_cluster_search ? join(",", data.aws_subnets.stack_application_search[0].ids) : ""
  stack_kms_key_alias_search               = var.create_ecs_cluster_search ? local.stack_secrets_search["kms_key_alias"] : ""
  stack_kms_key_id_search                  = var.create_ecs_cluster_search ? data.aws_kms_key.stack_kms_search[0].id : ""
  stack_notify_topic_slack_endpoint_search = var.create_ecs_cluster_search ? local.stack_secrets_search["notify_topic_slack_endpoint"] : ""
  stack_vpc_name_search                    = var.create_ecs_cluster_search ? local.stack_secrets_search["vpc_name"] : ""
  stack_vpc_id_search                      = var.create_ecs_cluster_search ? data.aws_vpc.stack_vpc_search[0].id : ""

  stack_parameter_store_secrets_search = var.create_ecs_cluster_search ? {
    "web-oauth2-client-id"     = local.stack_secrets_search["web_oauth2_client_id"],
    "web-oauth2-client-secret" = local.stack_secrets_search["web_oauth2_client_secret"],
    "web-oauth2-cookie-secret" = local.stack_secrets_search["web_oauth2_cookie_secret"],
    "web-oauth2-request-key"   = local.stack_secrets_search["web_oauth2_request_key"]
  } : {}

  asg_desired_instance_count_search = var.desired_task_count_search
  asg_max_instance_count_search     = var.max_task_count_search * 2
  asg_min_instance_count_search     = 0

  ecs_cluster_id_search          = var.use_ecs_cluster_search && var.create_ecs_cluster_search ? module.ecs_cluster_search[0].ecs_cluster_id : data.aws_ecs_cluster.ecs_cluster.id
  name_prefix_search             = var.use_ecs_cluster_search && var.create_ecs_cluster_search ? local.stack_name_prefix_search : local.name_prefix
  task_execution_role_arn_search = var.use_ecs_cluster_search && var.create_ecs_cluster_search ? module.ecs_cluster_search[0].ecs_task_execution_role_arn : data.aws_iam_role.ecs_cluster_iam_role.arn

  ec2_total_cpu_search = data.aws_ec2_instance_type.search.default_vcpus * 1024
  ec2_task_cpu_search  = local.ec2_total_cpu_search - (local.ec2_os_reserved_cpu + var.eric_cpus_search)
  ec2_total_mem_search = data.aws_ec2_instance_type.search.memory_size
  ec2_task_mem_search  = local.ec2_total_mem_search - (local.ec2_os_reserved_mem + var.eric_memory_search)
}
