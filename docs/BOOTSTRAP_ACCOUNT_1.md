# Bootstrap development account

The bootstrap is a separate Terraform root configuration that intentionally starts with local state. It creates the S3 backend required before the application pipeline can run and attaches the required state/application policies to the existing `task2-dev-elz` GitHub OIDC role.

It does not create application networking, ALB, ECS, NAT, SSM parameters, staging, or production resources.

## Prerequisites

- AWS CLI authenticated to account `598120810297` through a temporary administrator or IAM Identity Center session.
- Terraform `1.12.2`.
- Existing role `arn:aws:iam::598120810297:role/task2-dev-elz` with the immutable GitHub `main` branch trust policy.

## Run the local bootstrap

From the repository root:

```powershell
aws sts get-caller-identity
terraform -chdir=infra/bootstrap/terraform init
terraform -chdir=infra/bootstrap/terraform plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap/terraform apply bootstrap.tfplan
terraform -chdir=infra/bootstrap/terraform output
```

The expected account must be `598120810297`. Stop if it differs.

The bootstrap creates:

- `task02-pacetrainee-tfstate-598120810297-ap-south-1` in `ap-south-1`.
- SSE-S3 (`AES256`) default encryption.
- Versioning and S3-native lock-file support.
- Complete public-access blocking and bucket-owner-enforced ownership.
- A bucket policy that denies non-TLS requests.
- Development state access restricted to `platform-launchpad/account-1/*`.
- Development application permissions on the existing GitHub OIDC deployment role.

The local bootstrap state is ignored by Git. Store a secure backup; it records ownership of the bootstrap resources and must never be committed.

## GitHub repository variables

Create these repository-level Actions variables:

```text
AWS_ACCOUNT_ID_ACCOUNT_1=598120810297
AWS_REGION_ACCOUNT_1=ap-south-1
AWS_ROLE_ARN_ACCOUNT_1=arn:aws:iam::598120810297:role/task2-dev-elz
TF_STATE_BUCKET=task02-pacetrainee-tfstate-598120810297-ap-south-1
TF_STATE_REGION=ap-south-1
PROJECT_NAME=platform-launchpad
GHCR_OWNER=Elzabeth-L
GHCR_REPOSITORY_PREFIX=task02-pacetrainee
TERRAFORM_VERSION=1.12.2
TERRAGRUNT_VERSION=1.1.1
```

No AWS access keys, KMS variable, state-role variable, or GitHub Environment is required.

## First application deployment

1. Confirm the bootstrap apply completed.
2. Run **Infrastructure** with `operation=apply`, `target_account=account-1`, and image SHA `aa6bcc8d4e657bb8861ef578657f3507f565b26b`.
3. Confirm the exact saved plan applies and both ALB smoke tests pass.

For staging and production, create one matching OIDC role in each target account and give it infrastructure permissions plus identity-based S3 access. Add each exact role ARN manually to the centralized bucket policy with access restricted to its own state prefix. The bootstrap intentionally ignores bucket-policy body changes so later applies preserve these manual cross-account grants.
