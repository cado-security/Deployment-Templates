# This file is used to create the VPC, Subnets, and Security Groups for the Cado Deployment
locals {
  use_custom_networking = var.custom_networking == null ? false : true
  create_lb_networking  = var.custom_networking == null && var.public_deployment == false ? 1 : 0
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "selected_vpc_id" {
  id = local.use_custom_networking == true ? var.custom_networking.vpc_id : aws_vpc.vpc[0].id
}

data "aws_subnet" "primary_subnet" {
  id = local.use_custom_networking ? (
    var.public_deployment ? var.custom_networking.public_subnet_id : var.custom_networking.private_subnet_id
    ) : (
    var.public_deployment ? aws_subnet.subnet_public_a[0].id : aws_subnet.subnet_private[0].id
  )
}

resource "aws_vpc" "vpc" {
  count                = local.use_custom_networking == true ? 0 : 1
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    var.tags,
    {
      CadoFormation = "v2"
      Name          = "CadoVPCAlt"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  count  = local.use_custom_networking == true ? 0 : 1
  vpc_id = aws_vpc.vpc[0].id
  tags = merge(
    var.tags,
    {
      CadoStack = "CadoIGW"
    }
  )
}

resource "aws_route_table" "public_route_table" {
  count  = local.use_custom_networking == true ? 0 : 1
  vpc_id = aws_vpc.vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "CadoPublicRouteTable"
    }
  )
}

resource "aws_route_table_association" "route_table_assoc_public_a" {
  count          = local.use_custom_networking == true ? 0 : 1
  subnet_id      = aws_subnet.subnet_public_a[0].id
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_subnet" "subnet_public_a" {
  count                   = var.custom_networking != null ? 0 : 1
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = "10.5.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = merge(
    var.tags,
    {
      Name = "CadoPublicSubnetA"
    }
  )
  depends_on = [aws_vpc.vpc]
}

resource "aws_security_group" "security_group" {
  name        = "CadoSecGroupAlt"
  description = "Allow SSH and HTTPS Connections"
  vpc_id      = data.aws_vpc.selected_vpc_id.id
  tags        = var.tags

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.ssh_location
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.http_location
  }
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 24224
    to_port     = 24224
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 9200
    to_port     = 9200
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.selected_vpc_id.cidr_block]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "primary_subnet" {
  value = data.aws_subnet.primary_subnet
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}
