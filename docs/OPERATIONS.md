# Operations

## Routine deployment

Use the image workflow summary to obtain the SHA, deploy development first, inspect the plan artifact, verify `/health` and `/api/health`, then expand. Watch ECS events and alarms during rollout. Application Auto Scaling owns desired count after service creation; Terraform continues to own task definition and service configuration.

## Safe diagnostics

```bash
aws sts get-caller-identity
aws ecs describe-services --cluster <cluster> --services <frontend> <backend>
aws ecs list-tasks --cluster <cluster> --service-name <service>
aws ecs describe-tasks --cluster <cluster> --tasks <task-arns>
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
aws logs tail /ecs/<project-account>/backend --since 30m
aws cloudwatch describe-alarms --alarm-name-prefix <project-account>
aws ssm get-parameters --names <frontend-path> <backend-path>
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id>
```

Commands are read-only. Do not print parameter values into public logs, manually mutate ECS services, or disable state locks. Use the workflow for every infrastructure mutation.
