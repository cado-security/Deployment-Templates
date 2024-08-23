terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source                                = "./modules/networking"
  http_location                         = var.http_location
  ssh_location                          = var.ssh_location
  public_deployment                     = var.public_deployment
  private_load_balancer                 = var.private_load_balancer
  certificate_arn                       = var.certificate_arn
  custom_networking                     = var.custom_networking
  tags                                  = var.tags
  s3_bucket_id                          = module.deploy.s3_bucket_id
  load_balancer_delete_protection       = var.load_balancer_delete_protection
  load_balancer_access_logs_bucket_name = var.load_balancer_access_logs_bucket_name
}

module "iam" {
  source       = "./modules/iam"
  region       = var.region
  tags         = var.tags
  s3_bucket_id = module.deploy.s3_bucket_id
}

module "deploy" {
  source                        = "./modules/deploy"
  public_deployment             = var.public_deployment
  ami_id                        = var.ami_id
  vm_size                       = var.vm_size
  instance_worker_type          = var.instance_worker_type
  tags                          = var.tags
  finalize_cmd                  = var.finalize_cmd
  feature_flag_platform_upgrade = var.feature_flag_platform_upgrade
  key_name                      = var.key_name
  vol_size                      = var.vol_size
  primary_subnet                = module.networking.primary_subnet
  security_group_id             = module.networking.security_group_id
  lb_target_group_arn           = module.networking.lb_target_group_arn
  role_name                     = module.iam.role_name
  instance_role_name            = module.iam.instance_role_name
  proxy                         = var.proxy
  proxy_cert_url                = var.proxy_cert_url
  configure_cloudwatch          = var.configure_cloudwatch
  deploy_nfs                    = var.deploy_nfs
}
