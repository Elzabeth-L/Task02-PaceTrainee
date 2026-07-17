output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = var.aws_region
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.id
}

output "development_deployment_role_arn" {
  value = data.aws_iam_role.development_deployment.arn
}

output "github_repository_variables" {
  value = {
    AWS_ACCOUNT_ID_ACCOUNT_1 = var.aws_account_id
    AWS_REGION_ACCOUNT_1     = var.aws_region
    AWS_ROLE_ARN_ACCOUNT_1   = data.aws_iam_role.development_deployment.arn
    TF_STATE_BUCKET          = aws_s3_bucket.state.id
    TF_STATE_REGION          = var.aws_region
  }
}
