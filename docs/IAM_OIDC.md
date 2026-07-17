# IAM and GitHub OIDC

Create the GitHub OIDC provider and one deployment role per account. Trust `token.actions.githubusercontent.com`, require audience `sts.amazonaws.com`, and restrict the subject to the exact immutable owner/repository identity and `main` branch. For this repository the subject is `repo:Elzabeth-L@262315662/Task02-PaceTrainee@1302643669:ref:refs/heads/main`. Do not use wildcards that allow other owners, repositories, or branches.

Deployment permissions need only resources managed by the module: VPC/EC2 networking and security groups, ALB, ECS/task definitions, Application Auto Scaling, CloudWatch logs/alarms, narrowly prefixed IAM roles/pass-role, and the two prefixed SSM parameters. State access should be assumed through the dedicated state role and limited to its account state prefix plus the KMS key. Add explicit deny guardrails where organizational policy supports them.

OIDC sessions are short-lived and the workflow verifies `sts get-caller-identity` before planning and again before execution. Do not create repository access keys. Example policies belong in `docs/examples/iam/` after real owner/repository/account values are known; validate them with IAM Access Analyzer before use.
