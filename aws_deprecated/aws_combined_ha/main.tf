terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45"
    }
  }
  # Optional: add a backend to store tf state in AWS. Otherwise, make sure to keep you tfstate!  
}

# Should be updated 

variable "region" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ssh_location" {
  type = list(string)
}

variable "http_location" {
  type = list(string)
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to main vm and any spwaned workers"
  default     = {}
}

# Sizing options

variable "vm_size" {
  type    = string
  default = "t3a.2xlarge"
}

variable "vol_size" {
  type    = number
  default = 1000
}

# Load Balancer Options
variable "feature_flag_deploy_with_alb" {
  type = bool
}

# Load Balancer Options
variable "feature_flag_platform_upgrade" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type = string
}

# DO NOT CHANGE
variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

module "aws_roles" {
  source = "./../aws_roles"
  region = var.region
  s3_bucket_id = module.aws_common.s3_bucket_id
}

module "aws_ha" {
  source                        = "./../aws_ha"
  region                        = var.region
  vpc_id                        = module.aws_common.vpc_id
  subnet_id                     = module.aws_common.subnet_id
  subnet_b_id                   = module.aws_common.subnet_b_id
  subnet_c_id                   = module.aws_common.subnet_c_id
  security_group_id             = module.aws_common.security_group_id
  iam_instance_profile          = module.aws_common.iam_instance_profile
  vm_size                       = var.vm_size
  ami_id                        = var.ami_id
  key_name                      = var.key_name
  role_id                       = module.aws_roles.role_id
  s3_bucket_id                  = module.aws_common.s3_bucket_id
  feature_flag_platform_upgrade = var.feature_flag_platform_upgrade
  feature_flag_deploy_with_alb  = var.feature_flag_deploy_with_alb
  efs_ip_address                = module.aws_common.efs_ip_address
  tags                          = var.tags
  finalize_cmd                  = var.finalize_cmd
  certificate_arn               = var.certificate_arn
}

module "aws_common" {
  source           = "./../aws_common"
  region           = var.region
  ssh_location     = var.ssh_location
  http_location    = var.http_location
  role_id          = module.aws_roles.role_id
  instance_role_id = module.aws_roles.instance_role_id
  tags             = var.tags
}

