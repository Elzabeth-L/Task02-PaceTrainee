# Deployment flow

1. A relevant application change lands on `main`.
2. `build-images.yml` tests, builds, scans, smoke-tests, and publishes both full-SHA images.
3. An operator starts `infrastructure.yml` with apply, target, and that SHA.
4. The workflow verifies both images, assumes the target role, verifies the account, records SSM state, and temporarily updates both parameters.
5. Terragrunt creates a readable and exact binary plan plus SHA-256 checksum, then restores the previous SSM state before execution.
6. A new OIDC session verifies account and checksum, writes the selected image references, then applies only the saved plan.
7. ECS rolls out both task definitions and the workflow smoke-tests the ALB paths.

If apply fails, prior SSM values are restored where safe; infrastructure is not automatically rolled back without another reviewed plan.
