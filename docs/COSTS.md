# Cost warning

This stack is not free and is not guaranteed to remain within any Free Tier. Per account it creates an ALB plus capacity-unit usage, one NAT gateway plus processed bytes, one public IPv4 EIP, two continuously running Fargate tasks (more during deployment or autoscaling up to eight total), CloudWatch log ingestion/storage, three alarms, and S3 state requests/storage. Internet/NAT/cross-AZ/GHCR transfer can add charges. Optional notification services also cost money.

Defaults reduce—not eliminate—cost: 256 CPU/512 MiB tasks, one task per service, maximum four, one NAT, seven-day logs, no Container Insights, Lambda/EventBridge, custom metrics, access logs, domain, certificate, WAF, or multi-AZ NAT. One NAT introduces an availability trade-off. Review the AWS pricing calculator for each selected region, set budgets/anomaly alerts, destroy lab stacks promptly, and remember that two services always mean at least two running tasks.
