data "aws_availability_zones" "available" { state = "available" }
data "aws_ssm_parameter" "frontend_image" { name = var.frontend_image_parameter_name }
data "aws_ssm_parameter" "backend_image" { name = var.backend_image_parameter_name }

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
  frontend_image = nonsensitive(data.aws_ssm_parameter.frontend_image.value)
  backend_image  = nonsensitive(data.aws_ssm_parameter.backend_image.value)
  frontend_sha   = element(reverse(split(":", local.frontend_image)), 0)
  backend_sha    = element(reverse(split(":", local.backend_image)), 0)
}

check "distinct_availability_zones" {
  assert {
    condition     = length(distinct(local.azs)) == 2
    error_message = "The selected region must expose at least two distinct availability zones."
  }
}

check "immutable_images" {
  assert {
    condition = (
      can(regex(":[0-9a-f]{40}$", local.frontend_image)) &&
      can(regex(":[0-9a-f]{40}$", local.backend_image))
    )
    error_message = "Both SSM parameters must contain GHCR image URIs tagged with a full 40-character Git SHA."
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = local.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, {
    Name = "${local.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, {
    Name = "${local.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(local.common_tags, { Name = "${local.name}-public" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  tags       = merge(local.common_tags, { Name = "${local.name}-nat" })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(local.common_tags, { Name = "${local.name}-nat" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = merge(local.common_tags, { Name = "${local.name}-private-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Public HTTP entry point"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.common_tags, { Name = "${local.name}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each          = toset(var.allowed_ingress_cidrs)
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Configured public HTTP ingress"
}

resource "aws_security_group" "frontend" {
  name        = "${local.name}-frontend"
  description = "Frontend tasks; ALB ingress only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.common_tags, { Name = "${local.name}-frontend" })
}

resource "aws_security_group" "backend" {
  name        = "${local.name}-backend"
  description = "Backend tasks; ALB ingress only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.common_tags, { Name = "${local.name}-backend" })
}

resource "aws_vpc_security_group_ingress_rule" "frontend_from_alb" {
  security_group_id            = aws_security_group.frontend.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.frontend_port
  to_port                      = var.frontend_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.backend_port
  to_port                      = var.backend_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_frontend" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.frontend.id
  from_port                    = var.frontend_port
  to_port                      = var.frontend_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_backend" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.backend.id
  from_port                    = var.backend_port
  to_port                      = var.backend_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "task_https" {
  for_each          = { frontend = aws_security_group.frontend.id, backend = aws_security_group.backend.id }
  security_group_id = each.value
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "TLS egress for GHCR and AWS APIs through NAT"
}

resource "aws_vpc_security_group_egress_rule" "task_dns_udp" {
  for_each          = { frontend = aws_security_group.frontend.id, backend = aws_security_group.backend.id }
  security_group_id = each.value
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "VPC resolver DNS"
}

resource "aws_vpc_security_group_egress_rule" "task_dns_tcp" {
  for_each          = { frontend = aws_security_group.frontend.id, backend = aws_security_group.backend.id }
  security_group_id = each.value
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "VPC resolver DNS fallback"
}

resource "aws_lb" "this" {
  name                       = substr(local.name, 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public[*].id
  enable_deletion_protection = var.deletion_protection
  drop_invalid_header_fields = true
  tags                       = local.common_tags
}

resource "aws_lb_target_group" "frontend" {
  name                 = substr("${local.name}-fe", 0, 32)
  port                 = var.frontend_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.this.id
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = local.common_tags
}

resource "aws_lb_target_group" "backend" {
  name                 = substr("${local.name}-be", 0, 32)
  port                 = var.backend_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.this.id
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = "/api/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.name
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "service" {
  for_each          = toset(["frontend", "backend"])
  name              = "/ecs/${local.name}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  for_each           = toset(["frontend", "backend"])
  name               = "${local.name}-${each.key}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.common_tags
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["frontend"].arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  volume {
    name = "tmp"
  }
  container_definitions = jsonencode([{
    name             = "frontend", image = local.frontend_image, essential = true, readonlyRootFilesystem = true,
    portMappings     = [{ containerPort = var.frontend_port, hostPort = var.frontend_port, protocol = "tcp" }],
    environment      = [{ name = "GIT_SHA", value = local.frontend_sha }, { name = "ENVIRONMENT", value = var.environment }],
    mountPoints      = [{ sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }],
    healthCheck      = { command = ["CMD-SHELL", "wget -q -O /dev/null http://127.0.0.1:${var.frontend_port}/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 10 },
    linuxParameters  = { initProcessEnabled = true },
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.service["frontend"].name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "ecs" } }
  }])
  tags = local.common_tags
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task["backend"].arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  volume {
    name = "tmp"
  }
  container_definitions = jsonencode([{
    name         = "backend", image = local.backend_image, essential = true, readonlyRootFilesystem = true,
    portMappings = [{ containerPort = var.backend_port, hostPort = var.backend_port, protocol = "tcp" }],
    environment = [
      { name = "SERVICE_NAME", value = "${var.project_name}-api" }, { name = "ENVIRONMENT", value = var.environment },
      { name = "GIT_SHA", value = local.backend_sha }, { name = "APP_VERSION", value = "1.0.0" }, { name = "LOG_LEVEL", value = "INFO" }
    ],
    mountPoints      = [{ sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }],
    healthCheck      = { command = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.backend_port}/api/health',timeout=2)\" || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 10 },
    linuxParameters  = { initProcessEnabled = true },
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.service["backend"].name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "ecs" } }
  }])
  tags = local.common_tags
}

resource "aws_ecs_service" "service" {
  for_each = {
    frontend = { task = aws_ecs_task_definition.frontend.arn, sg = aws_security_group.frontend.id, tg = aws_lb_target_group.frontend.arn, port = var.frontend_port }
    backend  = { task = aws_ecs_task_definition.backend.arn, sg = aws_security_group.backend.id, tg = aws_lb_target_group.backend.arn, port = var.backend_port }
  }
  name                               = "${local.name}-${each.key}"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = each.value.task
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  enable_execute_command             = false
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [each.value.sg]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = each.value.tg
    container_name   = each.key
    container_port   = each.value.port
  }
  lifecycle {
    # Autoscaling owns this value after Terraform creates the service at desired_count.
    ignore_changes = [desired_count]
    precondition {
      condition     = var.desired_count >= 1
      error_message = "Services must start with at least one task."
    }
  }
  depends_on = [aws_lb_listener_rule.api]
  tags       = local.common_tags
}

resource "aws_appautoscaling_target" "service" {
  for_each           = aws_ecs_service.service
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${each.value.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each           = aws_appautoscaling_target.service
  name               = "${local.name}-${each.key}-cpu-60"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_metric_alarm" "zero_healthy_tasks" {
  for_each            = { frontend = aws_lb_target_group.frontend.arn_suffix, backend = aws_lb_target_group.backend.arn_suffix }
  alarm_name          = "${local.name}-${each.key}-zero-healthy-tasks"
  alarm_description   = "No healthy ${each.key} target is registered with the ALB."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  dimensions          = { LoadBalancer = aws_lb.this.arn_suffix, TargetGroup = each.value }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = var.alarm_actions
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name}-alb-5xx"
  alarm_description   = "Application Load Balancer is returning server errors."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions          = { LoadBalancer = aws_lb.this.arn_suffix }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  tags                = local.common_tags
}
