variable "project_name" {
  description = "Short project identifier used in AWS names."
  type        = string
  default     = "platform-launchpad"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be 3-31 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Account/environment alias."
  type        = string
}

variable "aws_region" {
  description = "AWS deployment region."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for this account's VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "allowed_ingress_cidrs" {
  description = "Public CIDRs permitted to reach the ALB on HTTP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "frontend_image_parameter_name" {
  description = "SSM String parameter containing the immutable frontend image URI."
  type        = string
}

variable "backend_image_parameter_name" {
  description = "SSM String parameter containing the immutable backend image URI."
  type        = string
}

variable "frontend_port" {
  type    = number
  default = 8080
}
variable "backend_port" {
  type    = number
  default = 8000
}
variable "desired_count" {
  type    = number
  default = 1
}
variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}
variable "autoscaling_max_capacity" {
  type    = number
  default = 4
}
variable "autoscaling_cpu_target" {
  type    = number
  default = 60
}
variable "task_cpu" {
  type    = number
  default = 256
}
variable "task_memory" {
  type    = number
  default = 512
}
variable "log_retention_days" {
  type    = number
  default = 7
}
variable "alarm_actions" {
  description = "Optional SNS action ARNs."
  type        = list(string)
  default     = []
}
variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
