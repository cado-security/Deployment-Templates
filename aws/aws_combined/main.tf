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

variable "certificate_arn" {
  type = string
}

# DO NOT CHANGE
variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
}

variable "proxy" {
  type        = string
  description = "Proxy string to use for outbound connections including port number & auth ex. user:pass@1.2.3.4:1234"
  default     = ""
}

variable "proxy_cert_url" {
  type        = string
  description = "Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert."
  default     = ""
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

module "aws_roles" {
  source = "./../aws_roles"
  region = var.region
  s3_bucket_id = module.aws.s3_bucket_id
}

module "aws_vpc" {
  source = "./../aws_vpc"
  region = var.region
}

module "aws" {
  source                       = "./../aws"
  region                       = var.region
  key_name                     = var.key_name
  ami_id                       = var.ami_id
  ssh_location                 = var.ssh_location
  http_location                = var.http_location
  vm_size                      = var.vm_size
  vol_size                     = var.vol_size
  feature_flag_deploy_with_alb = var.feature_flag_deploy_with_alb
  certificate_arn              = var.certificate_arn
  role_id                      = module.aws_roles.role_id
  instance_role_id             = module.aws_roles.instance_role_id
  vpc_id                       = module.aws_vpc.vpc_id
  finalize_cmd                 = var.finalize_cmd
  tags                         = var.tags
  proxy                        = var.proxy
  proxy_cert_url               = var.proxy_cert_url
}

