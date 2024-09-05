data "aws_iam_role" "role" {
  name = var.role_name
}

data "aws_iam_role" "instance_role" {
  name = var.instance_role_name
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "myCadoInstanceProfile"
  role        = data.aws_iam_role.instance_role.name
  path        = "/"
}

resource "aws_efs_file_system" "efs_fs" {
  count            = var.deploy_nfs == false ? 0 : 1
  encrypted        = true
  performance_mode = "generalPurpose"
  tags = merge(
    var.tags,
    {
      Cado = "CadoResponse"
    }
  )
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = var.deploy_nfs == false ? 0 : 1
  file_system_id  = aws_efs_file_system.efs_fs[0].id
  subnet_id       = var.primary_subnet.id
  security_groups = [var.security_group_id]
}

resource "aws_efs_access_point" "efs_access_point" {
  count          = var.deploy_nfs == false ? 0 : 1
  file_system_id = aws_efs_file_system.efs_fs[0].id
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
  force_destroy = true
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseBucket"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "CadoGlacierRule"
    status = "Enabled"
    filter {
      prefix = "glacier"
    }
    expiration {
      days = 365
    }
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "CadoPublicAccessBlockConfiguration" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_network_interface" "network_interface" {
  subnet_id       = var.primary_subnet.id
  security_groups = [var.security_group_id]
}

resource "aws_instance" "main" {
  tags = merge(
    var.tags,
    {
      Name = "CadoResponse"
    }
  )

  instance_type = var.vm_size
  metadata_options {
    http_tokens = "required"
  }
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
  availability_zone    = var.primary_subnet.availability_zone
  ami                  = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.profile.id
  user_data = join("\n", concat([
    "#!/bin/bash -x",
    "s3bucket=${aws_s3_bucket.bucket.id}",
    "aws_role=${data.aws_iam_role.role.arn}",
    "aws_rds_db=${""}",
    "aws_elastic_endpoint=${""}",
    "aws_elastic_id=${""}",
    "aws_stack_id=${""}", # not actually a stack id
    "feature_flag_http_proxy=${var.proxy}",
    "proxy_cert_url=${var.proxy_cert_url}",
    "feature_flag_platform_upgrade='${var.feature_flag_platform_upgrade}'",
    "feature_flag_deploy_with_alb='${!var.public_deployment}'",
    "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
    "echo bucket = $s3bucket >> /home/admin/processor/first_run.cfg",
    "echo deployment_mode = terraform >> /home/admin/processor/first_run.cfg",
    var.deploy_nfs ? "echo efs_ip = ${aws_efs_mount_target.efs_mount_target[0].ip_address} >> /home/admin/processor/first_run.cfg" : "",
    "echo local_workers = ${var.local_workers} >> /home/admin/processor/first_run.cfg",
    "echo aws_role = $aws_role >> /home/admin/processor/first_run.cfg",
    "echo worker_instance = ${var.instance_worker_type} >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_platform_upgrade = $feature_flag_platform_upgrade >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_private_workers = $feature_flag_deploy_with_alb >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_deploy_with_alb = $feature_flag_deploy_with_alb >> /home/admin/processor/first_run.cfg",
    "[ ! -z $aws_rds_db ] && echo sqlalchemy_host = $aws_rds_db >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_hostname = $aws_elastic_endpoint >> /home/admin/processor/first_run.cfg",
    "echo external_elastic_id = $aws_elastic_id >> /home/admin/processor/first_run.cfg",
    "echo aws_stack_id = $aws_stack_id >> /home/admin/processor/first_run.cfg",
    "echo PROXY_url = $feature_flag_http_proxy >> /home/admin/processor/first_run.cfg",
    "echo PROXY_cert_url = $proxy_cert_url >> /home/admin/processor/first_run.cfg",
    "echo minimum_role_deployment = true >> /home/admin/processor/first_run.cfg",
    ],
    [
      for k, v in var.tags :
      "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
    ],
    [
      join(" ", concat([
        "${var.finalize_cmd}",
        var.proxy != "" ? " --proxy ${var.proxy}" : "",
        var.proxy_cert_url != "" ? " --proxy-cert-url ${var.proxy_cert_url}" : "",
        "2>&1 | sudo tee /home/admin/processor/init_out"
      ]))
    ],
  ))
}

resource "aws_eip" "ip" {
  count    = var.public_deployment == true ? 1 : 0
  instance = aws_instance.main.id
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseIP"
    }
  )
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = var.primary_subnet.availability_zone
  size              = var.vol_size
  encrypted         = true
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseDataVolume"
    }
  )
  type = "gp3"
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.main.id
}

resource "aws_lb_target_group_attachment" "registered_target" {
  count            = var.public_deployment == true ? 0 : 1
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.main.id
}

resource "aws_cloudwatch_log_group" "cado_log_group" {
  count = var.configure_cloudwatch == false ? 0 : 1
  name  = "/var/logs/cado"
}

resource "aws_cloudwatch_log_stream" "cado_log_stream" {
  count          = var.configure_cloudwatch == false ? 0 : 1
  name           = "cado-logs-all"
  log_group_name = aws_cloudwatch_log_group.cado_log_group[0].name
  depends_on     = [aws_cloudwatch_log_group.cado_log_group[0]]
}

output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}
