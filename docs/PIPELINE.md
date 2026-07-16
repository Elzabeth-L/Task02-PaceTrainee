# Pipelines

## Image workflow

Push application change → frontend checks → backend checks → two Buildx images → Trivy scans → local container smoke tests → GHCR login → push the same full SHA → verify digests → metadata artifact and step summary. Documentation-only and Terraform-only changes do not trigger it. The artifact is informational; infrastructure always uses the operator-provided SHA.

## Plan

Manual plan/account → OIDC → account verification → read both existing SSM URIs → Terragrunt init/plan → binary plan, checksum, and readable artifact → no mutation.

## Apply

Manual apply/account/SHA → verify both public images → OIDC/account check → preserve SSM → temporarily update two URIs → create exact plan → restore SSM while waiting → account environment approval → redownload and checksum → new OIDC/account check → write approved URIs → exact-plan apply → ALB smoke tests.

## Destroy

Manual destroy plus exact phrase → OIDC/account check → destroy plan → checksum/artifact → protected approval → exact destroy-plan apply. State bucket, KMS key, and images are outside the module and remain.

Plan-only jobs may cancel stale runs. Apply/destroy execution uses `cancel-in-progress: false`.

![Pipeline](diagrams/pipeline-flow.svg)
