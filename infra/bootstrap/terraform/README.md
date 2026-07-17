# Local Terraform bootstrap

This configuration is intentionally separate from the application stacks and uses local state. It creates the centralized SSE-S3-encrypted, versioned state bucket and attaches development state/application permissions to the existing `task2-dev-elz` GitHub OIDC role.

It does not create the VPC, subnets, NAT gateway, ALB, ECS services, SSM parameters, staging role, or production role.

Run from an authenticated administrator or IAM Identity Center session in account `598120810297`:

```powershell
aws sts get-caller-identity
terraform -chdir=infra/bootstrap/terraform init
terraform -chdir=infra/bootstrap/terraform plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap/terraform apply bootstrap.tfplan
terraform -chdir=infra/bootstrap/terraform output
```

The local `terraform.tfstate` and plan are ignored by Git. Protect the local state because it records ownership of the bootstrap resources. Back it up securely after apply; do not commit or email it.

For staging and production, first create one branch-scoped GitHub OIDC deployment role in each target account. Then add the exact role ARNs and account aliases to `external_state_roles` and reapply this bootstrap. Each external role also needs an identity policy granting the same S3 actions only on its corresponding prefix.
