terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45"
    }
  }
}

# Should be updated 

variable "region" {
  type    = string
  default = "us-west-1"
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

variable "feature_flag_platform_upgrade" {
  type    = bool
  default = false
}

# Load Balancer Options

variable "feature_flag_deploy_with_alb" {
  type = bool
}
variable "certificate_arn" {
  type = string
}

# Sizing options

variable "vm_size" {
  type    = string
  default = "m5.4xlarge"
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

variable "vpc_id" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to main vm and any spwaned workers"
  default     = {}
}

# DO NOT CHANGE

variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
}

variable "proxy" {
  type = string
  description = "Proxy string to use for outbound connections including port number & auth ex. user:pass@1.2.3.4:1234"
  default = ""
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_iam_role" "role" {
  name = var.role_id
}

data "aws_iam_role" "instance_role" {
  name = var.instance_role_id
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "myCadoInstanceProfile"
  role        = data.aws_iam_role.instance_role.name
  path        = "/"
}

resource "aws_subnet" "subnet" {
  # The Primary Subnet the Cado VPC will use. Specify the IPv4 address range as a Classless Inter-Domain Routing (CIDR) block.
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet_b" {
  # The Secondary Subnet the Cado VPC will use. This is reserved if you want to create an ALB. Specify the IPv4 address range as a Classless Inter-Domain Routing (CIDR) block.
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.5.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_lb_target_group" "target_group" {
  count            = var.feature_flag_deploy_with_alb == true ? 1 : 0
  name             = "CadoTargetGroup"
  port             = 443
  protocol         = "HTTPS"
  protocol_version = "HTTP1"
  vpc_id           = data.aws_vpc.vpc.id
  health_check {
    protocol = "HTTPS"
    path     = "/"
  }
  tags = {
    Name = "CadoResponseTargetGroup"
  }
}

resource "aws_lb_target_group_attachment" "registered_target" {
  count            = var.feature_flag_deploy_with_alb == true ? 1 : 0
  target_group_arn = aws_lb_target_group.target_group[0].arn
  target_id        = aws_instance.main.id
}

resource "aws_lb" "load_balancer" {
  count              = var.feature_flag_deploy_with_alb == true ? 1 : 0
  name               = "CadoLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet_b.id]
  security_groups    = [aws_security_group.alb_security_group[0].id]
  tags = {
    Name = "CadoResponseLoadBalancer"
  }
}

resource "aws_lb_listener" "load_balancer_listener" {
  count             = var.feature_flag_deploy_with_alb == true ? 1 : 0
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }
}

resource "aws_security_group" "security_group" {
  name        = "CadoSecGroupAlt"
  description = "Allow SSH and HTTPS Connections"
  vpc_id      = data.aws_vpc.vpc.id

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
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 9200
    to_port     = 9200
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "alb_security_group" {
  name        = "ALBSecGroupAlt"
  count       = var.feature_flag_deploy_with_alb == true ? 1 : 0
  description = "Allow ALB Connections"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group_rule" "allow_alb_security_group" {
  count                    = var.feature_flag_deploy_with_alb == true ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_security_group[0].id
  security_group_id        = aws_security_group.security_group.id
}

resource "aws_network_interface" "network_interface" {
  subnet_id       = aws_subnet.subnet.id
  security_groups = [aws_security_group.security_group.id]
}


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
    uid = 0
    gid = 0
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
  force_destroy = true
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseBucket"
  })
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

resource "aws_instance" "main" {
  tags = merge(
    var.tags,
    {
      Name = "CadoResponse"
  })

  instance_type = var.vm_size
  ebs_block_device {
    device_name = "/dev/xvda"
    encrypted   = true
    volume_size = 100
  }
  key_name = var.key_name
  network_interface {
    network_interface_id = aws_network_interface.network_interface.id
    device_index         = 0
  }
  availability_zone    = data.aws_availability_zones.available.names[0]
  ami                  = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.profile.id
  user_data = join("\n", concat([
    "#!/bin/bash -x",
    "s3bucket=${aws_s3_bucket.bucket.id}",
    "aws_role=${data.aws_iam_role.role.arn}",
    "aws_rds_db=${""}",
    "aws_elastic_endpoint=${""}",
    "aws_elastic_id=${""}",
    "aws_stack_id=${""}", # not actually a stack id,
    "feature_flag_http_proxy=${var.proxy}",
    "feature_flag_platform_upgrade='${var.feature_flag_platform_upgrade}'",
    "feature_flag_deploy_with_alb='${var.feature_flag_deploy_with_alb}'",
    "feature_flag_deploy_with_elastic='${""}'",
    "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
    "echo bucket = $s3bucket >> /home/admin/processor/first_run.cfg",
    "echo processing_mode = scalable-vm >> /home/admin/processor/first_run.cfg",
    "echo efs_ip = ${aws_efs_mount_target.efs_mount_target.ip_address} >> /home/admin/processor/first_run.cfg",
    "echo aws_role = $aws_role >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_platform_upgrade = $feature_flag_platform_upgrade >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_deploy_with_alb = $feature_flag_deploy_with_alb >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_deploy_with_elastic = $feature_flag_deploy_with_elastic >> /home/admin/processor/first_run.cfg",
    "[ ! -z $aws_rds_db ] && echo sqlalchemy_host = $aws_rds_db >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_hostname = $aws_elastic_endpoint >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_id = $aws_elastic_id >> /home/admin/processor/first_run.cfg",
    "echo aws_stack_id = $aws_stack_id >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_http_proxy = $feature_flag_http_proxy >> /home/admin/processor/first_run.cfg",
    ],
    [
      for k, v in var.tags :
      "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
    ],
    [
      "${var.proxy == "" ? var.finalize_cmd : "${var.finalize_cmd} --proxy ${var.proxy}"} 2>&1 | sudo tee /home/admin/processor/init_out"

    ],

  ))
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.vol_size
  encrypted         = true
  tags = {
    Name = "CadoResponseDataVolume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.main.id
}

resource "aws_eip" "ip" {
  instance = aws_instance.main.id
  tags = {
    Name = "CadoResponseIP"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    CadoStack = "IGW"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = data.aws_vpc.vpc.id

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
