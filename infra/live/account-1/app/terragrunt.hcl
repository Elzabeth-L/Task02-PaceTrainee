include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}
terraform {
  source = "../../../modules/ecs-fargate-webapp"
} 
inputs = { vpc_cidr = "10.21.0.0/16" }
