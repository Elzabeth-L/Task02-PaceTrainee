variable "aws_account_id" {
  description = "AWS account that owns the centralized Terraform state bucket."
  type        = string
  default     = "598120810297"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "Region for the centralized Terraform state bucket."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix used by state keys and IAM resource scoping."
  type        = string
  default     = "platform-launchpad"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be a lowercase AWS-safe name."
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for centralized Terraform state."
  type        = string
  default     = "task02-pacetrainee-tfstate-598120810297-ap-south-1"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name."
  }
}

variable "development_deployment_role_name" {
  description = "Existing GitHub OIDC deployment role in the development account."
  type        = string
  default     = "task2-dev-elz"
}

variable "external_state_roles" {
  description = "Future staging/production role ARNs and their isolated state aliases. Keep empty for the first development deployment."
  type = map(object({
    role_arn      = string
    account_alias = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for item in values(var.external_state_roles) :
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", item.role_arn)) &&
      contains(["account-2", "account-3"], item.account_alias)
    ])
    error_message = "External entries must contain an IAM role ARN and account-2 or account-3 alias."
  }
}
