# IAM examples

Start with [`oidc-trust-policy.json`](oidc-trust-policy.json), replace every angle-bracket placeholder, and restrict every account role to the immutable repository identity on `main`. Generate account-specific permissions only after the regions, state bucket, KMS key, project prefix, and role names are known. Validate every resulting policy with IAM Access Analyzer. Do not commit real credentials.
