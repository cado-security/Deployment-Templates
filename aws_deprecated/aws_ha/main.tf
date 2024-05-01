// Variables
variable "region" {
  type    = string
  default = "us-west-1"
}

variable "vpc_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "subnet_b_id" {
  type = string
}

variable "subnet_c_id" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "s3_bucket_id" {
  type = string
}

variable "feature_flag_platform_upgrade" {
  type = bool
}

variable "feature_flag_deploy_with_alb" {
  type = bool
}

variable "efs_ip_address" {
  type = string
}

variable "role_id" {
  type = string
}

variable "finalize_cmd" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "certificate_arn" {
  type = string
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

variable "master_user_name" {
  type    = string
  default = "elastic"
}

# Not actually a stack id 
resource "random_string" "cado_stack_id" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

data "aws_iam_role" "role" {
  name = var.role_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

// Elasticsearch
resource "aws_secretsmanager_secret" "cado_elastic_secret" {
  name = "CadoResponse-elastic-${random_string.cado_stack_id.result}"
  tags = { "Elastic_Password" : "CadoResponse_elastic_password", "Name" : "CadoResponseSecret" }
}
resource "random_password" "cado_elastic_search_password" {
  length           = 32
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}
resource "aws_secretsmanager_secret_version" "cado_elastic_secret_version" {
  secret_id     = aws_secretsmanager_secret.cado_elastic_secret.id
  secret_string = jsonencode({ "username" : "elastic", "password" : "${random_password.cado_elastic_search_password.result}" })
}
resource "aws_elasticsearch_domain" "cado_elastic_domain" {
  domain_name           = "cado-elastic-${random_string.cado_stack_id.result}"
  elasticsearch_version = "OpenSearch_2.3"

  cluster_config {
    instance_count         = 2
    instance_type          = "m5.xlarge.elasticsearch"
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }

  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.master_user_name
      master_user_password = random_password.cado_elastic_search_password.result
    }
  }

  access_policies = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : "*"
        },
        Action : "es:*",
        Resource : "arn:aws:es:${var.region}:${local.account_id}:domain/cado*/*"
      }
    ]
  })

  ebs_options {
    ebs_enabled = true
    iops        = 3000
    volume_size = 200
    volume_type = "gp3"
    throughput  = 500
  }

  vpc_options {
    subnet_ids         = [var.subnet_id, var.subnet_b_id]
    security_group_ids = [var.security_group_id]
  }

}

// Elasticache
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name        = "cado-redis-${random_string.cado_stack_id.result}"
  description = "Cado Redis Subnet"
  subnet_ids  = [var.subnet_id, var.subnet_b_id]
}

resource "aws_security_group" "redis_security_group" {
  name        = "CacheRedisSecurity"
  description = "Allow Redis Connections"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
  depends_on = [data.aws_vpc.vpc]
}

resource "aws_elasticache_replication_group" "redis_replication_primary" {
  replication_group_id     = "redis-${random_string.cado_stack_id.result}"
  description              = "Redis cluster for CadoResponse"
  engine                   = "redis"
  node_type                = "cache.t4g.medium"
  subnet_group_name        = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids       = ["${aws_security_group.redis_security_group.id}"]
  multi_az_enabled         = false
  num_cache_clusters       = 1
  engine_version           = "7.0"
  port                     = 6379
  snapshot_retention_limit = 1
  snapshot_window          = "00:00-01:00"
  tags                     = { "Name" : "CadoRedis" }

  depends_on = [aws_security_group.redis_security_group, aws_elasticache_subnet_group.redis_subnet_group]
}

// Postgres RDS
resource "aws_db_subnet_group" "postgres" {
  subnet_ids = [var.subnet_id, var.subnet_b_id, var.subnet_c_id]
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "postgres" {
  name = "cado-rds-${random_string.cado_stack_id.result}"
  tags = {
    Name = "CadoResponse_cloud_service_key"
  }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id     = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({ "username" : "cadoapi", "password" : "${random_password.password.result}" })
}

resource "aws_rds_cluster" "postgres" {
  engine                    = "postgres"
  availability_zones        = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  database_name             = "cadomain"
  master_username           = jsondecode(aws_secretsmanager_secret_version.postgres.secret_string)["username"]
  master_password           = jsondecode(aws_secretsmanager_secret_version.postgres.secret_string)["password"]
  storage_type              = "io1"
  iops                      = 3000
  port                      = 3306
  allocated_storage         = 100
  db_subnet_group_name      = aws_db_subnet_group.postgres.name
  vpc_security_group_ids    = [var.security_group_id]
  db_cluster_instance_class = "db.m5d.large"
  skip_final_snapshot       = true
}

// Autoscaling
resource "aws_autoscaling_group" "autoscaling" {
  max_size            = 2
  min_size            = 2
  desired_capacity    = 2
  health_check_type   = "ELB"
  vpc_zone_identifier = [var.subnet_id, var.subnet_b_id]
  launch_template {
    id = aws_launch_template.launch_template.id

  }
  load_balancers = [aws_elb.load_balancer.name]
  tag {
    key                 = "Name"
    value               = "CadoResponse"
    propagate_at_launch = true
  }

}

resource "aws_launch_template" "launch_template" {
  image_id      = var.ami_id
  instance_type = var.vm_size
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
    }
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(join("\n", concat([
    "#!/bin/bash -x",
    "s3bucket=${var.s3_bucket_id}",
    "aws_role=${data.aws_iam_role.role.arn}",
    "aws_rds_db=${aws_rds_cluster.postgres.endpoint}",
    "aws_elastic_endpoint=${aws_elasticsearch_domain.cado_elastic_domain.endpoint}",
    "aws_elastic_id=${aws_elasticsearch_domain.cado_elastic_domain.id}",
    "aws_stack_id=${random_string.cado_stack_id.result}", # not actually a stack id
    "load_balancer_name=${aws_elb.load_balancer.name}",   # not actually a stack id
    "feature_flag_platform_upgrade='${var.feature_flag_platform_upgrade}'",
    "feature_flag_deploy_with_alb='${var.feature_flag_deploy_with_alb}'",
    "feature_flag_deploy_with_high_availability='${false}'",
    "aws_redis_db=${aws_elasticache_replication_group.redis_replication_primary.primary_endpoint_address}",
    "mkdir -p /home/admin/processor/envars",
    "echo -n $aws_redis_db > /home/admin/processor/envars/REDIS_HOST",
    "echo -n $aws_stack_id > /home/admin/processor/envars/AWS_STACK_ID",
    "echo -n $load_balancer_name > /home/admin/processor/envars/LOAD_BALANCER",
    "chown -R cado:cado /home/admin/processor/envars/",
    "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
    "echo bucket = $s3bucket >> /home/admin/processor/first_run.cfg",
    "echo processing_mode = scalable-vm >> /home/admin/processor/first_run.cfg",
    "echo efs_ip = ${var.efs_ip_address} >> /home/admin/processor/first_run.cfg",
    "echo aws_role = $aws_role >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_platform_upgrade = $feature_flag_platform_upgrade >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_deploy_with_alb = $feature_flag_deploy_with_alb >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_deploy_with_high_availability = $feature_flag_deploy_with_high_availability >> /home/admin/processor/first_run.cfg",
    "echo sqlalchemy_host = $aws_rds_db:3306 >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_hostname = $aws_elastic_endpoint >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_id = $aws_elastic_id >> /home/admin/processor/first_run.cfg",
    "echo aws_stack_id = $aws_stack_id >> /home/admin/processor/first_run.cfg",
    ],
    [
      for k, v in var.tags :
      "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
    ],
    [
      "${var.finalize_cmd} 2>&1 | sudo tee /home/admin/processor/init_out"
    ]
  )))
}

resource "aws_elb" "load_balancer" {
  security_groups = [var.security_group_id]
  subnets         = [var.subnet_id, var.subnet_b_id]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 10
    target              = "HTTPS:443/api/v2/system/status"
    interval            = 60
  }

  listener {
    instance_port      = 443
    instance_protocol  = "HTTPS"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = var.certificate_arn
  }


  tags = {
    Name = "CadoResponseLoadBalancer"
  }
}

