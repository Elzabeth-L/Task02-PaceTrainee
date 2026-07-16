# Remote state

Provision the shared S3 bucket and KMS key before running this repository. Enable versioning, block all public access, enforce TLS, encrypt with the KMS key, and restrict bucket/KMS access to the state role and three deployment roles. The module deliberately does not create its own backend.

Terragrunt uses native S3 lock files (`use_lockfile = true`) and independent keys: `<project>/<account>/app/terraform.tfstate`. Never disable locking. State and plans can contain infrastructure details: limit access, log access, retain versions, and test recovery by copying a prior state version—not by casually editing state.
