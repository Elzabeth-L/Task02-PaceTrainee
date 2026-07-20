# Remote state

The separate local Terraform bootstrap creates the centralized S3 backend before the application workflow runs. The bucket uses SSE-S3 (`AES256`) encryption, versioning, complete public-access blocking, bucket-owner-enforced ownership, and a TLS-only policy. No KMS key or separate Terraform state role is used.

Terragrunt uses native S3 lock files (`use_lockfile = true`) and independent keys:

```text
platform-launchpad/account-1/app/terraform.tfstate
platform-launchpad/account-2/app/terraform.tfstate
platform-launchpad/account-3/app/terraform.tfstate
```

The GitHub OIDC deployment role in each account accesses only its own prefix. Development access is same-account identity policy access. Staging and production access requires both an identity policy on the external role and a manually maintained exact-role allow statement in the centralized bucket policy. Terraform ignores bucket-policy body drift so it does not remove those manual grants.

Never grant an entire external account, disable locking, or edit state casually. State and plans contain infrastructure details; restrict repository/bucket access, retain versions, monitor CloudTrail, and test recovery using a copied prior version.
