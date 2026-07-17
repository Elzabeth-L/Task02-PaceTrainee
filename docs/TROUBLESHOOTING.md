# Troubleshooting runbook

| Symptom | Checks and safe response |
|---|---|
| Frontend/backend unhealthy | Inspect target reason, ECS events, task exit/health status, and matching log group. Confirm target port/path and ALB-to-task SG reference. Roll back by approved SHA if release-related. |
| ALB 502 | Look for process resets, wrong container port, malformed response, shutdown during rollout, or target timeout in ECS/app logs. |
| ALB 503 | Check target group has healthy registered task ENIs, service desired/running counts, placement failures, and circuit-breaker events. |
| `/api/*` reaches frontend | Confirm listener rule priority/path is `/api/*`, backend target group action, and no Nginx API proxy. Reconcile only through workflow. |
| Frontend cannot call backend | Browser request must be relative `/api/...`; verify ALB route and backend target health. Do not add direct frontend-task connectivity. |
| SPA refresh gives 404 | Verify Nginx `try_files $uri $uri/ /index.html` and that the request used frontend default action. |
| Cannot pull GHCR/private package | Use `docker manifest inspect` externally, verify package visibility is public, tag exists for both services, NAT route/EIP/IGW/DNS/TLS egress, and stopped-task reason. Private GHCR requires Secrets Manager repository credentials and is outside this default. |
| NAT/outbound missing | Inspect private default route to NAT, NAT availability/public subnet route to IGW, EIP, network ACLs, DNS settings, and task SG 443/53 egress. |
| SSM parameter missing | Plan deliberately fails. Create/update both values by a new apply run using a valid SHA; confirm role has prefixed SSM permissions. |
| SHA missing for one/both images | Do not deploy a mixed pair. Re-run build from the intended commit or select a SHA for which both manifests exist. |
| OIDC assumption fails | Check provider/audience, exact immutable repository subject on `main`, role ARN, workflow `id-token` permission, and organization SCPs. |
| Wrong AWS account | Identity verification stops the job. Correct the account ID/role mapping; never remove the assertion. |
| State lock | Find the active GitHub run and wait. If stale, investigate S3 lock ownership and follow an approved force-unlock procedure; never disable locking. |
| Plan checksum mismatch | Stop. Delete the run artifacts through normal retention and generate a new plan; never apply it. |
| Apply fails after SSM update | Workflow attempts safe parameter restoration and reports the SHA. Inspect state/services, then run a new apply—no automatic rollback. |
| Circuit-breaker rollback | Inspect deployment events and health/log failures. Fix/build both images or deploy an earlier pair through the approved workflow. |
| Autoscaling fails | Check scalable target, policy, service-linked role, CPU metrics, min/max, and CloudTrail authorization failures. |
| Zero-task/ALB 5xx alarm | Validate it is not deployment transience, inspect target health/service events/logs, and escalate if two consecutive periods persist. |
| Partial deployment across accounts | Treat accounts independently. Do not revert successful accounts automatically; fix or approved-rollback only the failed accounts. |
| Unexpected NAT/ALB cost | Review Cost Explorer tags, NAT bytes/cross-AZ paths, ALB LCUs, task scaling, log volume, and retained stacks. |
| Destroy blocked | Check ALB deletion protection and organizational policy. Change protection through an approved apply, then run a separately approved destroy. |
