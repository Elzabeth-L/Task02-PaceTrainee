# Infrastructure

One reusable Terraform module is instantiated by three Terragrunt live configurations. Account IDs, regions, OIDC roles, and shared-state settings come only from GitHub variables passed as environment variables. State keys are isolated as `<project>/<account>/app/terraform.tfstate` and use native S3 lock files.

Local `fmt`, `validate`, TFLint, and Checkov checks are supported. AWS plan, apply, and destroy are intentionally supported only through `.github/workflows/infrastructure.yml`.

See [`modules/ecs-fargate-webapp/README.md`](modules/ecs-fargate-webapp/README.md) for the complete module architecture, per-file responsibilities, and a description of every Terraform resource.
