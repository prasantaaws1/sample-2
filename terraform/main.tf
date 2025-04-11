provider "aws" {
  region     = "us-east-1"
}


terraform {
  backend "s3" {
    bucket          = "demo-20250508"
    key               = "statefiles/terraform.tfstate"
    region           = "us-east-1"
    dynamodb_table = "mytab"
    encrypt        = true
  }
}

module "ecr" {
  source   = "./modules/ecr"
}

module "network" {
  source   = "./modules/network"
  az_count = "2"
}

module "security" {
  source   = "./modules/security"
  app_port = 80
  vpc_id   = module.network.vpc_id
}

module "ecs_app" {
  source                       = "./modules/ecs"
  ec2_task_execution_role_name = "EcsTaskExecutionRoleName"
  ecs_auto_scale_role_name     = "EcsAutoScaleRoleName"
  app_image                    = "424567178047.dkr.ecr.us-east-1.amazonaws.com/app_repo:dev-image"
  app_port                     = 8000
  app_count                    = 1
  health_check_path            = "/"
  fargate_cpu                  = "1024"
  fargate_memory               = "2048"
  aws_region                   = terraform.workspace
  az_count                     = "2"
  subnets                      = module.network.public_subnet_ids
  sg_ecs_tasks                 = [module.security.ecs_tasks_security_group_id]
  vpc_id                       = module.network.vpc_id
  lb_security_groups           = [module.security.alb_security_group_id]
}


