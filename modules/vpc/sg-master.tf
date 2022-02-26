#https://docs.rke2.io/install/requirements/#networking

resource "aws_security_group" "master" {
  vpc_id = data.aws_vpc.cluster_vpc.id

  timeouts {
    create = "20m"
  }

  tags = merge(
    {
      "Name" = "${var.vpc_id}-master-sg"
    },
    var.tags,
  )

  //https://docs.rke2.io/install/requirements/ 
  //All nodes need to be able to reach other nodes over CNI VXLAN.
  dynamic "ingress" {
    for_each = var.cni_ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      description = ingress.value.description
      cidr_blocks = var.cidr_blocks
    }

  }

}
resource "aws_security_group_rule" "master_egress" {
  type              = "egress"
  security_group_id = aws_security_group.master.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master_ingress_icmp" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "icmp"
  cidr_blocks = var.cidr_blocks
  from_port   = -1
  to_port     = -1
}

resource "aws_security_group_rule" "master_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "master_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 6443
  to_port     = 6443
}

resource "aws_security_group_rule" "master_ingress_register_from_worker" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 9345
  to_port     = 9345
}


resource "aws_security_group_rule" "master_ingress_metrics" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 10250
  to_port     = 10250
}

resource "aws_security_group_rule" "master_ingress_etcd" {
  type              = "ingress"
  security_group_id = aws_security_group.master.id

  protocol  = "tcp"
  from_port = 2379
  to_port   = 2380
  self      = true
}





