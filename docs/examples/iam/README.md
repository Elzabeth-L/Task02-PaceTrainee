# IAM examples

Start with [`oidc-trust-policy.json`](oidc-trust-policy.json), replace every angle-bracket placeholder, and use only the matching `account-N` environment in each account. Generate account-specific permissions only after the regions, state bucket, KMS key, project prefix, and role names are known. Pin the OIDC subject and validate every resulting policy with IAM Access Analyzer. Do not commit real credentials.
