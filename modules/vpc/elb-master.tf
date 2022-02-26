resource "aws_lb" "api_internal" {
  name                             = "${var.vpc_id}-int"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.private.*.id
  internal                         = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.vpc_id}-int"
    },
    var.tags,
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb" "api_external" {
  count = local.public_endpoints ? 1 : 0

  name                             = "${var.vpc_id}-ext"
  load_balancer_type               = "network"
  subnets                          = data.aws_subnet.public.*.id
  internal                         = false
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      "Name" = "${var.vpc_id}-ext"
    },
    var.tags,
  )

  timeouts {
    create = "20m"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "api_internal" {
  name     = "${var.vpc_id}-aint"
  protocol = "TCP"
  port     = 6443
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-aint"
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

  # checks the HTTPS /readyz will generate 401 Unautorized.
  # still you can check with "kubectl get --raw='/readyz?verbose'"
  # https://kubernetes.io/docs/reference/using-api/health-checks/  
  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   interval            = 10
  #   port                = 6443
  #   protocol            = "HTTPS"
  #   path                = "/readyz"
  #   matcher             = "200-399,401"
  # }
}

resource "aws_lb_target_group" "api_external" {
  count = local.public_endpoints ? 1 : 0

  name     = "${var.vpc_id}-aext"
  protocol = "TCP"
  port     = 6443
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-aext"
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

  # checks the HTTPS /readyz will generate 401 Unautorized.
  # still you can check with "kubectl get --raw='/readyz?verbose'"
  # https://kubernetes.io/docs/reference/using-api/health-checks/  
  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   interval            = 10
  #   port                = 6443
  #   protocol            = "HTTPS"
  #   path                = "/readyz"
  #   matcher             = "200-399,401"
  # }
}

resource "aws_lb_target_group" "register" {
  name     = "${var.vpc_id}-rint"
  protocol = "TCP"
  port     = 9345
  vpc_id   = data.aws_vpc.cluster_vpc.id

  target_type = "ip"

  tags = merge(
    {
      "Name" = "${var.vpc_id}-rint"
    },
    var.tags,
  )

  # https://github.com/kubernetes/kops/issues/1647
  # https://github.com/kubernetes/kubernetes/issues/45746
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    port                = 9345
    protocol            = "TCP"
  }

  # checks the HTTPS /readyz will generate 403 Forbidden
  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   interval            = 10
  #   port                = 9345
  #   protocol            = "HTTPS"
  #   path                = "/v1-rke2/readyz"
  #   matcher             = "200-399,403"
  # }


}

resource "aws_lb_listener" "api_internal_api" {
  load_balancer_arn = aws_lb.api_internal.arn
  protocol          = "TCP"
  port              = "6443"

  default_action {
    target_group_arn = aws_lb_target_group.api_internal.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_internal_register" {
  load_balancer_arn = aws_lb.api_internal.arn
  protocol          = "TCP"
  port              = "9345"

  default_action {
    target_group_arn = aws_lb_target_group.register.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_external_api" {
  count = local.public_endpoints ? 1 : 0

  load_balancer_arn = aws_lb.api_external[0].arn
  protocol          = "TCP"
  port              = "6443"

  default_action {
    target_group_arn = aws_lb_target_group.api_external[0].arn
    type             = "forward"
  }
}



