output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = aws_lb.this.dns_name
}
output "alb_http_url" {
  description = "Public HTTP URL."
  value       = "http://${aws_lb.this.dns_name}"
}
output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}
output "frontend_service_name" {
  value = aws_ecs_service.service["frontend"].name
}
output "backend_service_name" {
  value = aws_ecs_service.service["backend"].name
}
output "frontend_image_uri" {
  value = local.frontend_image
}
output "backend_image_uri" {
  value = local.backend_image
}
output "vpc_id" {
  value = aws_vpc.this.id
}
