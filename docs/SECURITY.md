# Security

- The ALB on TCP 80 is the only public entry point. Add ACM/HTTPS and redirect HTTP for production.
- Tasks use private ENIs, no public IP, ALB-to-task SG references, separate ports/groups, no SSH, and no frontend-to-backend network rule.
- Containers are non-root, capability-dropped in smoke tests, minimal multi-stage images, and read-only at runtime with explicit temporary mounts.
- Full-SHA tags prevent silent replacement; Trivy, dependency validation, Checkov, TFLint, and linting detect common issues. Dependency updates are reviewed and committed directly to `main`; no automated dependency-update pull requests are configured.
- OIDC avoids long-lived keys. Trust policies must pin owner, repository, branch/environment, and audience; IAM/pass-role scopes must match project resources.
- Task roles are separate and empty. Execution role provides only normal image/log startup capabilities.
- Public GHCR images expose application layers to anyone. Private GHCR would require Secrets Manager repository credentials; ECR is preferred when private IAM-native distribution, scanning, or VPC endpoints matter.
- NAT allows controlled DNS and TLS egress; it is still an exfiltration path. Production can add network firewall/proxy controls and AWS endpoints.
- State and binary/readable plans can disclose infrastructure. Use encrypted/versioned S3, short artifact retention, restricted repository access, protected environments, and checksum verification.
- Destroy requires an exact phrase and approval. ALB deletion protection can intentionally block destruction.

Residual risks include HTTP transport, public images, supply-chain actions pinned mostly by major version rather than commit, a single NAT AZ, and manually configured GitHub protection rules.
