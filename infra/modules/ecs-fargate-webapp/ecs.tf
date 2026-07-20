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
