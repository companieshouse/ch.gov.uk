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
# Docker Container
# ------------------------------------------------------------------------------
variable "docker_registry" {
  description = "The FQDN of the Docker registry."
  type        = string
}

# ------------------------------------------------------------------------------
# Service performance and scaling configs
# ------------------------------------------------------------------------------
variable "desired_task_count" {
  default = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for this service"
  type = number
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
  default = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for the search specific service."
  type = number
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
  default = 1 # defaulted low for dev environments, override for production
  description = "The desired ECS task count for the officers specific service."
  type = number
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
  default = 256 # defaulted low for dev environments, override for production
  description = "The required cpu resource for this service. 1024 here is 1 vCPU"
  type = number
}

variable "required_memory" {
  default = 512 # defaulted low for perl service in dev environments, override for production
  description = "The required memory for this service"
  type = number
}

variable "use_fargate" {
  default     = true
  description = "If true, sets the required capabilities for all containers in the task definition to use FARGATE, false uses EC2"
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
  default     = 50 # 100 disables autoscaling using CPU as a metric
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

variable "eric_version" {
  description = "The version of the eric container to run."
  type        = string
}
