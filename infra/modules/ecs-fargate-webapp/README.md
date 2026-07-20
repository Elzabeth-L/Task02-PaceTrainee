# ECS Fargate web application module

This Terraform module deploys a two-tier web application on Amazon ECS Fargate. It creates a two-Availability-Zone VPC, a public Application Load Balancer (ALB), and private frontend and backend ECS services. The ALB sends normal requests to the frontend and `/api/*` requests to the backend.

Container image URIs are read from existing AWS Systems Manager Parameter Store String parameters during planning. Both images must use an immutable, full 40-character Git SHA tag. The module does not build or publish images and does not create the image parameters.

## Request and network flow

```text
Internet
  -> public ALB on TCP/80
      -> default route: frontend target group -> frontend Fargate task on TCP/8080
      -> /api/* route: backend target group -> backend Fargate task on TCP/8000

Private Fargate tasks
  -> private subnet route table
  -> one NAT gateway in the first public subnet
  -> internet gateway
  -> public GHCR and AWS API endpoints over TLS
```

The single NAT gateway is an intentional cost-conscious lab choice. It is shared by both private subnets and is therefore an Availability Zone dependency. A production architecture normally uses one NAT gateway per Availability Zone or evaluates private endpoints and Amazon ECR.

## File organization

| File | Responsibility |
|---|---|
| `versions.tf` | Terraform and AWS provider version constraints. |
| `variables.tf` | Module input contract and defaults. |
| `locals.tf` | AWS lookups, shared names/tags, image parsing, and configuration checks. |
| `network.tf` | VPC, subnets, internet access, NAT, and routing. |
| `security-groups.tf` | ALB/task security groups and explicit traffic rules. |
| `alb.tf` | Load balancer, target groups, listener, and API path routing. |
| `iam.tf` | ECS task trust policy, execution role, and application task roles. |
| `ecs.tf` | ECS cluster, logs, task definitions, and ECS services. |
| `autoscaling.tf` | ECS desired-count scaling targets and CPU policies. |
| `monitoring.tf` | ALB target-health and load-balancer 5xx alarms. |
| `outputs.tf` | Deployment identifiers and the public application endpoint. |

Terraform loads all `.tf` files in this directory as one module. File names organize the code but do not change resource addresses or dependency resolution.

## `versions.tf`

### `terraform.required_version`

Accepts Terraform versions from `1.10.0` up to, but not including, `2.0.0`. This prevents execution with an older Terraform version that may not support the configuration and avoids silently adopting a future major version.

### `terraform.required_providers.aws`

Pins the HashiCorp AWS provider to `6.54.0`. Exact provider pinning makes local and pipeline behavior reproducible.

## `locals.tf`

### Data sources

| Address | Purpose |
|---|---|
| `data.aws_availability_zones.available` | Retrieves Availability Zones currently available in the selected AWS Region. The first two are used for the VPC layout. |
| `data.aws_ssm_parameter.frontend_image` | Reads the complete frontend container URI from the SSM parameter supplied through `frontend_image_parameter_name`. |
| `data.aws_ssm_parameter.backend_image` | Reads the complete backend container URI from the SSM parameter supplied through `backend_image_parameter_name`. |

### Local values

| Local | Purpose |
|---|---|
| `local.name` | Produces the shared `<project_name>-<environment>` naming prefix. |
| `local.azs` | Selects two Availability Zones for the public/private subnet pairs. |
| `local.common_tags` | Merges caller-supplied tags with `Project`, `Environment`, and `ManagedBy=Terraform`. |
| `local.frontend_image` / `local.backend_image` | Converts SSM values to non-sensitive image strings so they can be used in task definitions and outputs. These URIs are identifiers, not credentials. |
| `local.frontend_sha` / `local.backend_sha` | Extracts the tag after the final colon and exposes it to the containers as `GIT_SHA`. |

### Checks

| Address | Purpose |
|---|---|
| `check.distinct_availability_zones` | Stops planning if the Region does not provide two distinct Availability Zones. |
| `check.immutable_images` | Stops planning unless both image URIs end with a lowercase, full 40-character Git SHA tag. This prevents mutable tags such as `latest` from being deployed. |

## `network.tf`

| Resource | Purpose and important behavior |
|---|---|
| `aws_vpc.this` | Creates the account/environment VPC from `vpc_cidr`, with DNS support and DNS hostnames enabled. |
| `aws_internet_gateway.this` | Attaches an internet gateway to the VPC. It provides the public route used by the ALB and NAT gateway. |
| `aws_subnet.public[0..1]` | Creates two public-tier subnets in separate Availability Zones. For the default `/16` layout, `cidrsubnet(..., 8, 0/1)` produces two `/24` networks. Automatic public IPv4 assignment is disabled. |
| `aws_subnet.private[0..1]` | Creates two private application subnets in the same two Availability Zones. CIDR indexes `10` and `11` keep them separate from the public subnets. ECS tasks receive no public IP addresses. |
| `aws_route_table.public` | Adds `0.0.0.0/0` through the internet gateway. |
| `aws_route_table_association.public[0..1]` | Associates both public subnets with the public route table. |
| `aws_eip.nat` | Allocates the stable public IPv4 address used by the NAT gateway. Its explicit internet-gateway dependency ensures VPC internet connectivity is established first. |
| `aws_nat_gateway.this` | Creates one NAT gateway in the first public subnet. Private tasks use it for outbound GHCR and AWS API access. It does not accept unsolicited inbound internet traffic. |
| `aws_route_table.private[0..1]` | Creates one route table per private subnet and sends `0.0.0.0/0` to the shared NAT gateway. |
| `aws_route_table_association.private[0..1]` | Associates each private subnet with its corresponding private route table. |

## `security-groups.tf`

Security groups are created without broad inline rules. Dedicated VPC security-group rule resources make each permitted flow explicit.

| Resource | Purpose and allowed traffic |
|---|---|
| `aws_security_group.alb` | Security group attached to the public ALB. |
| `aws_vpc_security_group_ingress_rule.alb_http` | Allows TCP/80 from each CIDR in `allowed_ingress_cidrs`. The default is `0.0.0.0/0`. |
| `aws_security_group.frontend` | Security group attached only to frontend Fargate tasks. |
| `aws_security_group.backend` | Security group attached only to backend Fargate tasks. |
| `aws_vpc_security_group_ingress_rule.frontend_from_alb` | Allows the ALB security group to reach frontend tasks on `frontend_port` only. |
| `aws_vpc_security_group_ingress_rule.backend_from_alb` | Allows the ALB security group to reach backend tasks on `backend_port` only. The frontend does not receive direct network permission to call the backend. |
| `aws_vpc_security_group_egress_rule.alb_to_frontend` | Allows ALB egress to the frontend security group on `frontend_port`. |
| `aws_vpc_security_group_egress_rule.alb_to_backend` | Allows ALB egress to the backend security group on `backend_port`. |
| `aws_vpc_security_group_egress_rule.task_https` | Allows frontend and backend task egress on TCP/443 to reach public GHCR and AWS APIs through NAT. |
| `aws_vpc_security_group_egress_rule.task_dns_udp` | Allows task DNS queries over UDP/53 within the VPC CIDR. |
| `aws_vpc_security_group_egress_rule.task_dns_tcp` | Allows TCP/53 fallback for DNS responses within the VPC CIDR. |

No rule exposes a task port directly to the internet. Only the ALB security group can initiate connections to the application ports.

## `alb.tf`

| Resource | Purpose and important behavior |
|---|---|
| `aws_lb.this` | Creates an internet-facing Application Load Balancer across both public subnets. Invalid HTTP header fields are dropped. Optional deletion protection is controlled by `deletion_protection`. |
| `aws_lb_target_group.frontend` | Registers frontend task IP addresses on `frontend_port`. ALB health checks call `/health`; a target becomes healthy after two successful checks. |
| `aws_lb_target_group.backend` | Registers backend task IP addresses on `backend_port`. ALB health checks call `/api/health`. |
| `aws_lb_listener.http` | Listens publicly on HTTP port 80. Its default action forwards requests to the frontend target group. |
| `aws_lb_listener_rule.api` | Matches `/api/*` at priority `10` and forwards those requests to the backend target group. |

The module currently provides HTTP only. A production deployment should add an ACM certificate, an HTTPS listener, and an HTTP-to-HTTPS redirect.

## `iam.tf`

| Resource/data source | Purpose |
|---|---|
| `data.aws_iam_policy_document.ecs_tasks_assume` | Builds the trust policy that allows the `ecs-tasks.amazonaws.com` service principal to assume ECS roles. |
| `aws_iam_role.execution` | ECS execution role used by the Fargate agent for task startup operations such as writing container logs. It is not the application’s runtime identity. |
| `aws_iam_role_policy_attachment.execution` | Attaches the AWS-managed `AmazonECSTaskExecutionRolePolicy` to the execution role. |
| `aws_iam_role.task["frontend"]` / `["backend"]` | Creates separate runtime identities for the two applications. No application permissions are attached currently, so the containers do not receive unnecessary AWS API access. |

Execution and task roles are intentionally separate: the ECS agent uses the execution role, while application code receives the relevant task role credentials.

## `ecs.tf`

### Cluster and logging

| Resource | Purpose |
|---|---|
| `aws_ecs_cluster.this` | Creates the environment’s ECS cluster. Container Insights is disabled to avoid additional lab monitoring cost. |
| `aws_cloudwatch_log_group.service["frontend"]` / `["backend"]` | Creates independent log groups at `/ecs/<name>/<service>`, applies `log_retention_days`, and receives `awslogs` output from each container. |

### Task definitions

| Resource | Purpose and security/runtime configuration |
|---|---|
| `aws_ecs_task_definition.frontend` | Registers an x86-64 Linux Fargate task using the immutable frontend image. It runs on port `8080` by default, has a read-only root filesystem, mounts a writable task-scoped `/tmp`, enables an init process, writes to the frontend log group, and performs a container-level `/health` check. |
| `aws_ecs_task_definition.backend` | Registers an equivalent backend Fargate task on port `8000` by default. It receives service/environment/version/log-level variables and performs a Python-based `/api/health` check. |

Both task definitions use the configurable `task_cpu` and `task_memory`, the shared execution role, and separate application task roles. The writable `/tmp` volume supports software that requires temporary files while the rest of the container filesystem remains read-only.

### Services

`aws_ecs_service.service` creates one service for each entry in its `frontend`/`backend` map.

Each service:

- runs on Fargate platform `1.4.0`;
- starts at `desired_count` and requires at least one task;
- places tasks across the two private subnets without public IP addresses;
- attaches only the corresponding task security group and ALB target group;
- uses a 60-second load-balancer health-check grace period;
- enables the ECS deployment circuit breaker with automatic rollback;
- waits for the ALB listener/routing rule before service creation; and
- ignores only later drift on `desired_count`, because Application Auto Scaling owns that value after creation.

Task-definition revisions, network configuration, target groups, and all other service settings remain managed by Terraform.

## `autoscaling.tf`

| Resource | Purpose |
|---|---|
| `aws_appautoscaling_target.service` | Registers each ECS service’s `DesiredCount` as a scalable target, bounded by `autoscaling_min_capacity` and `autoscaling_max_capacity`. |
| `aws_appautoscaling_policy.cpu` | Creates a target-tracking policy per service using `ECSServiceAverageCPUUtilization`. The default target is 60%, with a 60-second scale-out cooldown and a conservative 300-second scale-in cooldown. |

Frontend and backend services scale independently based on their own average CPU utilization.

## `monitoring.tf`

| Resource | Purpose and trigger |
|---|---|
| `aws_cloudwatch_metric_alarm.zero_healthy_tasks["frontend"]` / `["backend"]` | Watches the target group’s minimum `HealthyHostCount`. It alarms when the count remains below one for two consecutive 60-second periods. Missing data is treated as breaching. |
| `aws_cloudwatch_metric_alarm.alb_5xx` | Watches `HTTPCode_ELB_5XX_Count` and alarms when the ALB produces at least five 5xx responses in two consecutive 60-second periods. Missing data is treated as healthy. |

The optional `alarm_actions` list can contain SNS topic ARNs or other CloudWatch-compatible action ARNs. With its default empty value, alarms change state but send no notification.

## Inputs (`variables.tf`)

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | `string` | `platform-launchpad` | AWS-safe project prefix. Validation requires 3-31 lowercase letters, numbers, or hyphens and a leading letter. |
| `environment` | `string` | required | Account/environment alias, such as `account-1`. |
| `aws_region` | `string` | required | Deployment Region and CloudWatch Logs Region used in task definitions. |
| `vpc_cidr` | `string` | `10.20.0.0/16` | Address range from which the four subnet CIDRs are derived. |
| `allowed_ingress_cidrs` | `list(string)` | `["0.0.0.0/0"]` | Source IPv4 CIDRs allowed to reach ALB port 80. |
| `frontend_image_parameter_name` | `string` | required | SSM parameter containing the immutable frontend image URI. |
| `backend_image_parameter_name` | `string` | required | SSM parameter containing the immutable backend image URI. |
| `frontend_port` | `number` | `8080` | Frontend container, target-group, and security-group port. |
| `backend_port` | `number` | `8000` | Backend container, target-group, and security-group port. |
| `desired_count` | `number` | `1` | Number of tasks used when each ECS service is created. Must be at least one. |
| `autoscaling_min_capacity` | `number` | `1` | Lowest desired count Application Auto Scaling may select. |
| `autoscaling_max_capacity` | `number` | `4` | Highest desired count Application Auto Scaling may select. |
| `autoscaling_cpu_target` | `number` | `60` | Target average ECS service CPU utilization percentage. |
| `task_cpu` | `number` | `256` | Fargate CPU units assigned to each task definition. |
| `task_memory` | `number` | `512` | Fargate task memory in MiB. Must form a valid Fargate combination with `task_cpu`. |
| `log_retention_days` | `number` | `7` | CloudWatch Logs retention for both services. |
| `alarm_actions` | `list(string)` | `[]` | Optional action ARNs invoked when alarms change to ALARM. |
| `deletion_protection` | `bool` | `false` | Enables ALB deletion protection when true. |
| `tags` | `map(string)` | `{}` | Additional resource tags merged with the module’s standard tags. |

## Outputs (`outputs.tf`)

| Output | Description |
|---|---|
| `alb_dns_name` | Public DNS name assigned to the ALB. |
| `alb_http_url` | Complete `http://` application endpoint used by the deployment smoke test. |
| `ecs_cluster_name` | ECS cluster name for operational queries. |
| `frontend_service_name` | Frontend ECS service name. |
| `backend_service_name` | Backend ECS service name. |
| `frontend_image_uri` | Exact immutable frontend image URI read from SSM and placed in the task definition. |
| `backend_image_uri` | Exact immutable backend image URI read from SSM and placed in the task definition. |
| `vpc_id` | ID of the VPC created by the module. |

## State and deployment behavior

Each Terragrunt live configuration instantiates this same module with a different account alias, AWS account, Region, VPC CIDR, SSM paths, and remote-state key. Moving resource blocks between files does not change state addresses. Renaming a resource type/name or changing `count`/`for_each` keys can change addresses and must be reviewed with a Terraform plan.

The GitHub infrastructure workflow creates an exact binary plan, stores its checksum as an artifact, and applies that same plan in the execution job. A plan-only run does not modify infrastructure or SSM image parameters.
