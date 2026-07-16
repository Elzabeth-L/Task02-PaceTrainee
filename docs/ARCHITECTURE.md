# Architecture

Each account receives an independent runtime stack. The internet-facing ALB spans public subnets in two AZs. Its default action targets Nginx frontend tasks; priority rule 10 targets FastAPI for `/api/*`. Both services use `awsvpc` networking and `ip` target groups in private subnets. Task security groups accept only their matching port from the ALB security group; tasks receive no public IP.

Private tasks resolve DNS inside the VPC and use one NAT gateway for TLS egress to public GHCR and AWS APIs. The single NAT is a cost-conscious lab decision and an AZ dependency; production normally deploys one per AZ or evaluates ECR/VPC endpoints.

Terraform reads complete immutable frontend/backend URIs from account-specific SSM String parameters. ECS execution roles pull images and publish logs; application task roles are separate and intentionally have no policies. CloudWatch retains logs for seven days, alarms on zero healthy targets and ALB 5xx responses, and Application Auto Scaling independently targets 60% CPU for each service from one to four tasks.

See [the editable diagram](diagrams/architecture.excalidraw) and [SVG](diagrams/architecture.svg).
