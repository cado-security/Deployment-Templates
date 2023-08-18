terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45"
    }
  }
}

variable "region" {
  type    = string
  default = "us-west-1"
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    CadoFormation = "v1"
    Name          = "CadoVPC"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id

}
