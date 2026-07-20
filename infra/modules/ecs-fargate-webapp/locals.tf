data "aws_availability_zones" "available" { state = "available" }
data "aws_ssm_parameter" "frontend_image" { name = var.frontend_image_parameter_name }
data "aws_ssm_parameter" "backend_image" { name = var.backend_image_parameter_name }

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
  frontend_image = nonsensitive(data.aws_ssm_parameter.frontend_image.value)
  backend_image  = nonsensitive(data.aws_ssm_parameter.backend_image.value)
  frontend_sha   = element(reverse(split(":", local.frontend_image)), 0)
  backend_sha    = element(reverse(split(":", local.backend_image)), 0)
}

check "distinct_availability_zones" {
  assert {
    condition     = length(distinct(local.azs)) == 2
    error_message = "The selected region must expose at least two distinct availability zones."
  }
}

check "immutable_images" {
  assert {
    condition = (
      can(regex(":[0-9a-f]{40}$", local.frontend_image)) &&
      can(regex(":[0-9a-f]{40}$", local.backend_image))
    )
    error_message = "Both SSM parameters must contain GHCR image URIs tagged with a full 40-character Git SHA."
  }
}
