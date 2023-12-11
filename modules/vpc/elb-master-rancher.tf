
resource "aws_security_group_rule" "master_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 443
  to_port     = 443
}

resource "aws_security_group_rule" "master_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 80
  to_port     = 80
}

resource "aws_lb" "ingress_internal" {
  name                             = "${var.vpc_id}-ing-int"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.private.*.id
  internal                         = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.vpc_id}-ing-int"
    },
    var.tags,
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb" "ingress_external" {
  count = local.public_endpoints ? 1 : 0

  name                             = "${var.vpc_id}-ing-ext"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.public.*.id
  internal                         = false
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.vpc_id}-ing-ext"
    },
    var.tags,
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "ingress_internal_https" {
  name     = "${var.vpc_id}-https-int"
  protocol = "TCP"
  port     = 443
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-https-int"
    },
    var.tags,
  )

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    port                = 443
    protocol            = "TCP"
  }

}

resource "aws_lb_target_group" "ingress_internal_http" {
  name     = "${var.vpc_id}-http-int"
  protocol = "TCP"
  port     = 80
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-http-int"
    },
    var.tags,
  )

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    port                = 80
    protocol            = "TCP"
  }

}

resource "aws_lb_target_group" "ingress_external_https" {
  count = local.public_endpoints ? 1 : 0

  name     = "${var.vpc_id}-https-ext"
  protocol = "TCP"
  port     = 443
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-https-ext"
    },
    var.tags,
  )

  # https://github.com/kubernetes/kops/issues/1647
  # https://github.com/kubernetes/kubernetes/issues/45746
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    port                = 6443
    protocol            = "TCP"
  }

}

resource "aws_lb_target_group" "ingress_external_http" {
  count = local.public_endpoints ? 1 : 0

  name     = "${var.vpc_id}-http-ext"
  protocol = "TCP"
  port     = 80
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-http-ext"
    },
    var.tags,
  )

  # https://github.com/kubernetes/kops/issues/1647
  # https://github.com/kubernetes/kubernetes/issues/45746
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    port                = 6443
    protocol            = "TCP"
  }

}


resource "aws_lb_listener" "ingress_internal_https" {
  load_balancer_arn = aws_lb.ingress_internal.arn
  protocol          = "TCP"
  port              = "443"

  default_action {
    target_group_arn = aws_lb_target_group.ingress_internal_https.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "ingress_internal_http" {
  load_balancer_arn = aws_lb.ingress_internal.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.ingress_internal_http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "ingress_external_https" {
  load_balancer_arn = aws_lb.ingress_external[0].arn
  protocol          = "TCP"
  port              = "443"

  default_action {
    target_group_arn = aws_lb_target_group.ingress_external_https[0].arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "ingress_external_http" {
  load_balancer_arn = aws_lb.ingress_external[0].arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.ingress_external_http[0].arn
    type             = "forward"
  }
}





