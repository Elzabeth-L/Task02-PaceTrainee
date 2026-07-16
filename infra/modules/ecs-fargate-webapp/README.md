# ECS Fargate web application module

Creates one two-AZ VPC, a public ALB, private frontend/backend Fargate services, target groups, independent CPU autoscaling, logs, IAM roles, and alarms. Image URIs are read from two existing SSM String parameters at plan time. The module deliberately creates one NAT gateway for lab cost control; production should normally use one per AZ.

The service starts at `desired_count = 1`. Application Auto Scaling owns subsequent desired-count changes, so Terraform ignores only drift on that attribute while continuing to manage task definitions and every other service setting.
