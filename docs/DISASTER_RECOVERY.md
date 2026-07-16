# Disaster recovery

Source, full-SHA GHCR images, versioned remote state, and repository configuration are recovery assets. Protect and periodically test them. For state corruption, stop workflows, preserve the current object, inspect S3 versions/audit logs, restore the last verified version, and run a plan before approval. For an account loss, create new narrowly trusted roles, update non-secret variables, and apply the same module to a replacement account/CIDR after governance approval.

GHCR retention must preserve known-good image pairs. If an image is missing, rebuild from the exact source commit only after verifying reproducibility and publish both images under a new reviewed release SHA. This design has no database or persistent application data, so runtime recovery is infrastructure and artifact recovery. Shared state is a regional dependency; production can add bucket replication and a documented KMS recovery design.
