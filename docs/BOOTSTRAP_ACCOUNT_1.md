# Bootstrap account 1

This is the only prerequisite infrastructure created outside the application workflow. It establishes GitHub OIDC and the encrypted remote-state boundary; it does not create the VPC, NAT gateway, load balancer, ECS services, alarms, logs, or SSM image parameters.

## Create the bootstrap stack

1. Sign in to the intended AWS account with an administrator bootstrap session and MFA, and verify its 12-digit account ID before continuing.
2. Select region `ap-south-1` (Mumbai).
3. Open CloudFormation and choose **Create stack → With new resources**.
4. Upload [`infra/bootstrap/account-1.yaml`](../infra/bootstrap/account-1.yaml).
5. Use stack name `platform-launchpad-bootstrap`.
6. Keep these parameters:

   ```text
   GitHubOwner                 Elzabeth-L
   GitHubOwnerId               262315662
   GitHubRepository            Task02-PaceTrainee
   GitHubRepositoryId          1302643669
   ProjectName                 platform-launchpad
   StateBucketName             task02-pacetrainee-tfstate-<YOUR_12_DIGIT_ACCOUNT_ID>-ap-south-1
   CreateGitHubOidcProvider    true
   ```

7. If IAM already contains `token.actions.githubusercontent.com`, set `CreateGitHubOidcProvider` to `false` and paste its ARN into `ExistingGitHubOidcProviderArn`.
8. Supply `PermissionsBoundaryArn` only when your organization requires one.
9. Acknowledge that the stack creates named IAM resources and create it.
10. Wait for `CREATE_COMPLETE`, then copy the values from **Outputs**.

The bucket and KMS key use retention policies, bucket versioning, public-access blocking, TLS enforcement, KMS rotation, and a state-only role. The OIDC deployment role trusts only this repository's immutable owner/repository identity on `main`.

## Map outputs to GitHub variables

In GitHub, open **Settings → Secrets and variables → Actions → Variables** and create:

```text
AWS_ACCOUNT_ID_ACCOUNT_1=<YOUR_12_DIGIT_ACCOUNT_ID>
AWS_REGION_ACCOUNT_1=ap-south-1
AWS_ROLE_ARN_ACCOUNT_1=<DeploymentRoleArn output>
TF_STATE_BUCKET=<StateBucketName output>
TF_STATE_REGION=ap-south-1
TF_STATE_ROLE_ARN=<StateRoleArn output>
TF_STATE_KMS_KEY_ARN=<StateKmsKeyArn output>
PROJECT_NAME=platform-launchpad
GHCR_OWNER=Elzabeth-L
GHCR_REPOSITORY_PREFIX=task02-pacetrainee
TERRAFORM_VERSION=1.12.2
TERRAGRUNT_VERSION=1.1.1
```

Do not put AWS access keys in GitHub. Accounts 2 and 3 remain unset until account 1 is deployed and accepted.

## First deployment sequence

1. Run **Build immutable images** on `main`.
2. Make both newly created GHCR packages public.
3. Copy the full source SHA from the workflow summary.
4. Run **Infrastructure** with `operation=apply`, `target_account=account-1`, and that SHA.
5. Confirm the exact saved plan is applied, then check the workflow smoke tests and ALB URL from its summary.
