# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
variable "environment" {
  description = "The environment name, defined in envrionments vars."
  type        = string
}

variable "aws_region" {
  default     = "eu-west-2"
  description = "The AWS region for deployment."
  type        = string
}

variable "aws_profile" {
  default     = "development-eu-west-2"
  description = "The AWS profile to use for deployment."
  type        = string
}

# ------------------------------------------------------------------------------
# Miscellaneous variables
# ------------------------------------------------------------------------------
variable "docker_registry" {
  description = "The FQDN of the Docker registry."
  type        = string
}

variable "instance_refresh_lambda_s3_key" {
  default     = ""
  description = "The object key, including prefix, of the instance refresh lambda deployment package"
  type        = string
}

# ------------------------------------------------------------------------------
# Service performance and scaling configs
# ------------------------------------------------------------------------------
variable "desired_task_count" {
  default     = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for this service"
  type        = number
}

variable "min_task_count" {
  default     = 1
  description = "The minimum number of tasks for this service."
  type        = number
}

variable "max_task_count" {
  default     = 3 # defaulted low for dev environments, override for production
  description = "The maximum number of tasks for this service."
  type        = number
}

variable "desired_task_count_search" {
  default     = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for the search specific service."
  type        = number
}

variable "min_task_count_search" {
  default     = 1
  description = "The minimum number of tasks for the search specific service."
  type        = number
}

variable "max_task_count_search" {
  default     = 3 # defaulted low for dev environments, override for production
  description = "The maximum number of tasks for the search specific service."
  type        = number
}

variable "desired_task_count_officers" {
  default     = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for the officers specific service."
  type        = number
}

variable "min_task_count_officers" {
  default     = 1
  description = "The minimum number of tasks for the officers specific service."
  type        = number
}

variable "max_task_count_officers" {
  default     = 3 # defaulted low for dev environments, override for production
  description = "The maximum number of tasks for the officers specific service."
  type        = number
}

variable "required_cpus" {
  default     = 256 # defaulted low for dev environments, override for production
  description = "The required cpu resource for this service. 1024 here is 1 vCPU"
  type        = number
}

variable "required_memory" {
  default     = 512 # defaulted low for perl service in dev environments, override for production
  description = "The required memory for this service"
  type        = number
}

variable "required_cpus_officers" {
  default     = 256 # defaulted low for dev environments, override for production
  description = "The required cpu resource for the officers service. 1024 here is 1 vCPU"
  type        = number
}

variable "required_memory_officers" {
  default     = 512 # defaulted low for perl service in dev environments, override for production
  description = "The required memory for the officers service"
  type        = number
}

variable "required_cpus_search" {
  default     = 256 # defaulted low for dev environments, override for production
  description = "The required cpu resource for the search service. 1024 here is 1 vCPU"
  type        = number
}

variable "required_memory_search" {
  default     = 512 # defaulted low for perl service in dev environments, override for production
  description = "The required memory for the search service"
  type        = number
}

variable "use_fargate" {
  default     = true
  description = "If true, sets the required capabilities for all containers in the default service task definition to use FARGATE, false uses EC2"
  type        = bool
}

variable "use_fargate_officers" {
  default     = true
  description = "If true, sets the required capabilities for all containers in the Officers service task definition to use FARGATE, false uses EC2"
  type        = bool
}

variable "use_fargate_search" {
  default     = true
  description = "If true, sets the required capabilities for all containers in the Search service task definition to use FARGATE, false uses EC2"
  type        = bool
}

variable "use_capacity_provider" {
  default     = true
  description = "Whether to use a capacity provider instead of setting a launch type for the service"
  type        = bool
}

variable "service_autoscale_enabled" {
  default     = true
  description = "Whether to enable service autoscaling, including scheduled autoscaling"
  type        = bool
}

variable "service_autoscale_target_value_cpu" {
  default     = 15
  description = "Target CPU percentage for the ECS Service to autoscale on"
  type        = number
}

variable "service_scaledown_schedule" {
  default     = ""
  description = "The schedule to use when scaling down the number of tasks to zero."
  type        = string
}

variable "service_scaleup_schedule" {
  default     = ""
  description = "The schedule to use when scaling up the number of tasks to their normal desired level."
  type        = string
}

variable "service_autoscale_scale_in_cooldown" {
  default     = 300
  description = "Cooldown in seconds for ECS Service scale in"
  type        = number
}

variable "service_autoscale_scale_out_cooldown" {
  default     = 120
  description = "Cooldown in seconds for ECS Service scale out"
  type        = number
}

variable "use_task_container_healthcheck" {
  default     = true
  description = "Defines whether task-level container healthchecks will be implemented for the default service (true) or not (false)"
  type        = bool
}

variable "use_task_container_healthcheck_search" {
  default     = true
  description = "Defines whether task-level container healthchecks will be implemented for the search service (true) or not (false)"
  type        = bool
}

variable "use_task_container_healthcheck_officers" {
  default     = true
  description = "Defines whether task-level container healthchecks will be implemented for the officers service (true) or not (false)"
  type        = bool
}

# ----------------------------------------------------------------------
# Cloudwatch alerts
# ----------------------------------------------------------------------
variable "cloudwatch_alarms_enabled" {
  default     = true
  description = "Whether to create a standard set of cloudwatch alarms for the service.  Requires an SNS topic to have already been created for the stack."
  type        = bool
}

# ----------------------------------------------------------------------
# ALB listener options
# ----------------------------------------------------------------------
variable "enable_listener" {
  default     = false
  description = "Whether or not to create the default service listener rules."
  type        = bool
}

variable "enable_listener_search" {
  default     = false
  description = "Whether or not to create the search service listener rules."
  type        = bool
}

variable "enable_listener_officers" {
  default     = false
  description = "Whether or not to create the officers service listener rules."
  type        = bool
}

# ------------------------------------------------------------------------------
# Service environment variable configs
# ------------------------------------------------------------------------------
variable "ssm_version_prefix" {
  default     = "SSM_VERSION_"
  description = "String to use as a prefix to the names of the variables containing variables and secrets version."
  type        = string
}

variable "use_set_environment_files" {
  default     = true
  description = "Toggle default global and shared  environment files"
  type        = bool
}

variable "chgovuk_version" {
  description = "The version of the ch.gov.uk container to run."
  type        = string
}

variable "eric_cpus" {
  default     = 256
  description = "The required cpu resource for eric. 1024 here is 1 vCPU"
  type        = number
}

variable "eric_memory" {
  default     = 512
  description = "The required memory for eric"
  type        = number
}

variable "eric_cpus_officers" {
  default     = 256
  description = "The required cpu resource for officer eric. 1024 here is 1 vCPU"
  type        = number
}

variable "eric_memory_officers" {
  default     = 512
  description = "The required memory for officer eric"
  type        = number
}

variable "eric_cpus_search" {
  default     = 256
  description = "The required cpu resource for search eric. 1024 here is 1 vCPU"
  type        = number
}

variable "eric_memory_search" {
  default     = 512
  description = "The required memory for search eric"
  type        = number
}

variable "eric_version" {
  description = "The version of the eric container to run."
  type        = string
}

variable "create_service_dashboard" {
  default     = true
  description = "Defines whether a CloudWatch dashboard is created for the default ECS service (true) or not (false)"
  type        = bool
}

variable "create_service_dashboard_officers" {
  default     = true
  description = "Defines whether a CloudWatch dashboard is created for the officers ECS service (true) or not (false)"
  type        = bool
}

variable "create_service_dashboard_search" {
  default     = true
  description = "Defines whether a CloudWatch dashboard is created for the search ECS service (true) or not (false)"
  type        = bool
}

# ------------------------------------------------------------------------------
# Common EC2 variables
# ------------------------------------------------------------------------------
variable "ec2_ami_id" {
  default     = ""
  description = "The AMI id to use when launching instances in the ASG; when set, will be used over the result of an AMI lookup"
  type        = string
}

variable "ec2_ami_name_regex" {
  default     = "^al2023-ami-ecs-hvm-2023.*-kernel-6.1-x86_64"
  description = "The regex pattern to use to lookup an AMI when ec2_ami_id is empty"
  type        = string
}

variable "ec2_ami_owners" {
  default     = ["amazon"]
  description = "A list of AWS marketplace AMI owners used to filter the AMI lookup when ec2_ami_id is empty"
  type        = list(string)
}

variable "ec2_key_pair_name" {
  description = "The keypair name to use when deploying EC2 instances"
  type        = string
}

# ------------------------------------------------------------------------------
# Default service EC2 variables
# ------------------------------------------------------------------------------
variable "create_ecs_cluster_default" {
  default     = false
  description = "Defines whether a dedicated ECS cluster should be created for the default service (true) or not (false)"
  type        = bool
}

variable "enable_instance_refresh_default" {
  default     = false
  description = "Defines whether the instance refresh lambda configuration is deployed for the default cluster (true) or not (false)"
  type        = bool
}

variable "instance_refresh_schedule_default" {
  default     = "rate(6 hours)"
  description = "The cron-like or AWS Scheduler expression that defines the refresh cadence for the default cluster instances"
  type        = string
}

variable "use_ecs_cluster_default" {
  default     = false
  description = "Defines whether the dedicated ECS cluster should be used for the default service (true) or not (false)"
  type        = bool
}

variable "ec2_instance_type_default" {
  default     = "t3a.small"
  description = "The EC2 instance type to use for the default service"
  type        = string
}

variable "asg_scaledown_schedule_default" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling down the number of EC2 instances to zero for the default service ASG"
}

variable "asg_scaleup_schedule_default" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling up the number of EC2 instances to their normal desired level for the default service ASG"
}

# ------------------------------------------------------------------------------
# Officers service EC2 variables
# ------------------------------------------------------------------------------
variable "create_ecs_cluster_officers" {
  default     = false
  description = "Defines whether a dedicated ECS cluster should be created for the Officers service (true) or not (false)"
  type        = bool
}

variable "enable_instance_refresh_officers" {
  default     = false
  description = "Defines whether the instance refresh lambda configuration is deployed for the Officers cluster (true) or not (false)"
  type        = bool
}

variable "instance_refresh_schedule_officers" {
  default     = "rate(6 hours)"
  description = "The cron-like or AWS Scheduler expression that defines the refresh cadence for the Officers cluster instances"
  type        = string
}

variable "use_ecs_cluster_officers" {
  default     = false
  description = "Defines whether the dedicated ECS cluster should be used for the Officers service (true) or not (false)"
  type        = bool
}

variable "ec2_instance_type_officers" {
  default     = "t3a.small"
  description = "The EC2 instance type to use for the Officers service"
  type        = string
}

variable "asg_scaledown_schedule_officers" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling down the number of EC2 instances to zero for the Officers service ASG"
}

variable "asg_scaleup_schedule_officers" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling up the number of EC2 instances to their normal desired level for the Officers service ASG"
}

# ------------------------------------------------------------------------------
# Search service EC2 variables
# ------------------------------------------------------------------------------
variable "create_ecs_cluster_search" {
  default     = false
  description = "Defines whether a dedicated ECS cluster should be created for the Search service (true) or not (false)"
  type        = bool
}

variable "enable_instance_refresh_search" {
  default     = false
  description = "Defines whether the instance refresh lambda configuration is deployed for the Search cluster (true) or not (false)"
  type        = bool
}

variable "instance_refresh_schedule_search" {
  default     = "rate(6 hours)"
  description = "The cron-like or AWS Scheduler expression that defines the refresh cadence for the Search cluster instances"
  type        = string
}

variable "use_ecs_cluster_search" {
  default     = false
  description = "Defines whether the dedicated ECS cluster should be used for the Search service (true) or not (false)"
  type        = bool
}

variable "ec2_instance_type_search" {
  default     = "t3a.small"
  description = "The EC2 instance type to use for the Search service"
  type        = string
}

variable "asg_scaledown_schedule_search" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling down the number of EC2 instances to zero for the Search service ASG"
}

variable "asg_scaleup_schedule_search" {
  default     = ""
  type        = string
  description = "The schedule to use when scaling up the number of EC2 instances to their normal desired level for the Search service ASG"
}
