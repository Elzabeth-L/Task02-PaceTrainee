locals {
  account_config = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name   = local.account_config.locals.account_name
  account_id     = get_env("TG_AWS_ACCOUNT_ID")
  aws_region     = get_env("TG_AWS_REGION")
  project_name   = get_env("TG_PROJECT_NAME", "platform-launchpad")
  state_bucket   = get_env("TG_STATE_BUCKET")
  state_region   = get_env("TG_STATE_REGION")
}

remote_state {
  backend = "s3"
  config = {
    bucket       = local.state_bucket
    key          = "${local.project_name}/${local.account_name}/app/terraform.tfstate"
    region       = local.state_region
    encrypt      = true
    use_lockfile = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.account_name}"
      ManagedBy   = "Terraform"
    }
  }
  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

inputs = {
  project_name                  = local.project_name
  environment                   = local.account_name
  aws_region                    = local.aws_region
  frontend_image_parameter_name = "/${local.project_name}/${local.account_name}/frontend-image-uri"
  backend_image_parameter_name  = "/${local.project_name}/${local.account_name}/backend-image-uri"
}
