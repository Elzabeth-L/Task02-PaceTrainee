# Variables and secrets

Create these GitHub Actions repository variables:

```text
AWS_ACCOUNT_ID_ACCOUNT_1          AWS_ROLE_ARN_ACCOUNT_1          AWS_REGION_ACCOUNT_1
AWS_ACCOUNT_ID_ACCOUNT_2          AWS_ROLE_ARN_ACCOUNT_2          AWS_REGION_ACCOUNT_2
AWS_ACCOUNT_ID_ACCOUNT_3          AWS_ROLE_ARN_ACCOUNT_3          AWS_REGION_ACCOUNT_3
TF_STATE_BUCKET                   TF_STATE_REGION                 PROJECT_NAME
GHCR_OWNER                        GHCR_REPOSITORY_PREFIX           TERRAFORM_VERSION
TERRAGRUNT_VERSION
```

Recommended initial tool versions are Terraform `1.12.2` and a tested Terragrunt release compatible with it. `PROJECT_NAME` and the GHCR prefix should use lowercase names. GitHub Environments are not currently used; all values are repository-level Actions variables.

These identifiers are not secrets. Use GitHub secrets only for genuine secret material or optional notification credentials. Do not configure long-lived AWS credential variables. `GITHUB_TOKEN` is automatically issued and used only by the image workflow to publish packages. Avoid printing role/session data; log masking is not a substitute for avoiding disclosure.

SSM parameter paths are deterministic:

```text
/<project>/account-1/frontend-image-uri
/<project>/account-1/backend-image-uri
```

The pattern repeats for accounts 2 and 3. Values are non-secret complete public GHCR image URIs.
