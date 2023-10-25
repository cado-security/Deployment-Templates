terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45"
    }
  }
}

// Variables
variable "region" {
  type    = string
  default = "us-west-1"
}

variable "ssh_location" {
  type = list(string)
}

variable "http_location" {
  type = list(string)
}

variable "vm_size" {
  type    = string
  default = "t3a.2xlarge"
}

variable "vol_size" {
  type    = number
  default = 1000
}

variable "role_id" {
  type = string
}

variable "instance_role_id" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to main vm and any spwaned workers"
  default     = {}
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_iam_role" "instance_role" {
  name = var.instance_role_id
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "myCadoInstanceProfile"
  role        = data.aws_iam_role.instance_role.name
  path        = "/"
}

// Networking
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet" {
  # The Primary Subnet the Cado VPC will use. Specify the IPv4 address range as a Classless Inter-Domain Routing (CIDR) block.
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet_b" {
  # The Secondary Subnet the Cado VPC will use. This is reserved if you want to create an ALB. Specify the IPv4 address range as a Classless Inter-Domain Routing (CIDR) block.
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.5.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_subnet" "subnet_c" {
  # The Tertiary Subnet the Cado VPC will use. Specify the IPv4 address range as a Classless Inter-Domain Routing (CIDR) block.
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.5.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]
}

resource "aws_security_group" "security_group" {
  name        = "CadoSecGroupAlt"
  description = "Allow SSH and HTTPS Connections"
  vpc_id      = aws_vpc.vpc.id

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
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 9200
    to_port     = 9200
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }
  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_network_interface" "network_interface" {
  subnet_id       = aws_subnet.subnet.id
  security_groups = [aws_security_group.security_group.id]
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    CadoStack = "IGW"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "route_table_assoc" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}


resource "aws_route_table_association" "route_table_assoc_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "route_table_assoc_c" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.route_table.id
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

// Data storage
resource "aws_efs_file_system" "efs_fs" {
  encrypted        = true
  performance_mode = "generalPurpose"
  tags = {
    Cado = "CadoResponse"
  }
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id  = aws_efs_file_system.efs_fs.id
  subnet_id       = aws_subnet.subnet.id
  security_groups = [aws_security_group.security_group.id]
}

resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs_fs.id
  posix_user {
    uid = 100
    gid = 1000
  }
  root_directory {
    path = "/process"
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = 0755
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "cadoresponse"
  acl           = "private"
  lifecycle_rule {
    id      = "CadoGlacierRule"
    prefix  = "glacier"
    enabled = true
    expiration {
      days = 365
    }
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

// Outputs
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "subnet_b_id" {
  value = aws_subnet.subnet_b.id
}

output "subnet_c_id" {
  value = aws_subnet.subnet_c.id
}

output "network_interface_id" {
  value = aws_network_interface.network_interface.id
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.profile.id
}

output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}

output "efs_ip_address" {
  value = aws_efs_mount_target.efs_mount_target.ip_address
}
