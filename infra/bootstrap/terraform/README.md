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

For staging and production, create one branch-scoped GitHub OIDC deployment role in each target account. Cross-account grants are maintained manually in the centralized S3 bucket policy so role ARNs are not stored in this configuration. The bootstrap ignores policy-body drift and therefore preserves those manual statements on later applies. Each external role also needs an identity policy granting S3 access; the temporary `AdministratorAccess` choice already supplies that identity-side permission.
