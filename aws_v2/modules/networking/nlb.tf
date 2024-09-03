# Creates a network load balancer and associated resources for private deployments

locals {
  use_default_subnets  = var.custom_networking != null ? var.custom_networking.private_subnet_id == "" ? true : false : true
  create_nlb_resources = var.public_deployment == false && local.use_default_subnets == true ? 1 : 0
  subnet_a_id          = local.use_custom_networking == true ? var.custom_networking.public_subnet_id : aws_subnet.subnet_public_a[0].id
  subnet_b_id          = local.use_custom_networking == true ? var.custom_networking.public_subnet_b_id : var.public_deployment == true ? "" : aws_subnet.subnet_public_b[0].id
}

resource "aws_eip" "ip" {
  count = local.create_nlb_resources
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseIP"
    }
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = local.create_nlb_resources
  subnet_id     = local.subnet_a_id
  allocation_id = aws_eip.ip[0].allocation_id
}

resource "aws_route_table" "private_route_table" {
  count  = local.create_nlb_resources
  vpc_id = aws_vpc.vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "CadoPrivateSubnetRouteTable"
    }
  )
}

resource "aws_route_table_association" "route_table_assoc_private" {
  count          = local.create_nlb_resources
  subnet_id      = aws_subnet.subnet_private[0].id
  route_table_id = aws_route_table.private_route_table[0].id
}

resource "aws_route_table_association" "route_table_assoc_public_b" {
  count          = local.create_nlb_resources
  subnet_id      = aws_subnet.subnet_public_b[0].id
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_subnet" "subnet_private" {
  count                   = local.create_lb_networking
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = "10.5.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = merge(
    var.tags,
    {
      Name = "CadoPrivateSubnet"
    }
  )
}

resource "aws_subnet" "subnet_public_b" {
  count                   = local.create_lb_networking
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = "10.5.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = merge(
    var.tags,
    {
      Name = "CadoPublicSubnetB"
    }
  )
}

resource "aws_lb" "load_balancer" {
  count                      = var.public_deployment == true ? 0 : 1
  name_prefix                = "CadoLB"
  internal                   = var.private_load_balancer
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  ip_address_type            = "ipv4"
  subnets                    = [local.subnet_a_id, local.subnet_b_id]
  security_groups            = [aws_security_group.alb_security_group[0].id]
  enable_deletion_protection = var.load_balancer_delete_protection
  idle_timeout               = 305

  access_logs {
    bucket  = var.load_balancer_access_logs_bucket_name
    prefix  = "cado-lb-access-logs"
    enabled = var.load_balancer_access_logs_bucket_name == "" ? false : true
  }

  tags = merge(
    var.tags,
    {
      Name = "CadoResponseLoadBalancer"
    }
  )
  depends_on = [var.s3_bucket_id]
}

resource "aws_lb_target_group" "target_group" {
  count            = var.public_deployment == true ? 0 : 1
  name_prefix      = "CadoTG"
  port             = 443
  protocol         = "HTTPS"
  protocol_version = "HTTP1"
  vpc_id           = data.aws_vpc.selected_vpc_id.id
  health_check {
    protocol = "HTTPS"
    path     = "/"
  }
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseTargetGroup"
    }
  )
}

resource "aws_lb_listener" "load_balancer_listener" {
  count             = var.public_deployment == true ? 0 : 1
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }
  tags = merge(
    var.tags,
    {
      Name = "CadoResponseListener"
    }
  )
}

resource "aws_security_group" "alb_security_group" {
  name        = "ALBSecGroupAlt"
  count       = var.public_deployment == true ? 0 : 1
  description = "Allow ALB Connections"
  vpc_id      = data.aws_vpc.selected_vpc_id.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.http_location
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_alb_security_group" {
  count                    = var.public_deployment == true ? 0 : 1
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_security_group[0].id
  security_group_id        = aws_security_group.security_group.id
}

output "lb_target_group_arn" {
  value = var.public_deployment == true ? "" : aws_lb_target_group.target_group[0].arn
}
