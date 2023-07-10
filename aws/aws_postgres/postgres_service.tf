terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45"
    }
  }
}

variable "db_size"{
  type    = number
  default = 10
}

variable "db_type"{
  type    = string
  default = "db.t3.micro"
}

variable "security_group_ids"{
  type = list(string)
}
variable "subnet_ids"{
  type = list(string)
}

resource "aws_db_subnet_group" "postgres" {
  subnet_ids  = var.subnet_ids
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

locals {
  postgres_secret = {
    username = "cadoapi"
    password = random_password.password.result
  }
}

resource "aws_secretsmanager_secret" "postgres" {
  name = "cloud_service_key"
  tags = {
    Name = "CadoResponseSecret"
  }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode(local.postgres_secret)
}

resource "aws_db_instance" "postgres" {
  identifier = "cado-postgres"
  allocated_storage    = var.db_size
  engine               = "postgres"
  instance_class       = var.db_type
  name                 = "cadomain"
  username             = local.postgres_secret.username
  password             = local.postgres_secret.password
  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name = aws_db_subnet_group.postgres.name
  skip_final_snapshot  = true
}

output "postgres_host" {
    value = aws_db_instance.postgres.endpoint
}