#https://docs.rke2.io/install/requirements/#networking

resource "aws_security_group" "worker" {
  vpc_id = data.aws_vpc.cluster_vpc.id

  timeouts {
    create = "20m"
  }

  tags = merge(
    {
      "Name" = "${var.vpc_id}-worker-sg"
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

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  security_group_id = aws_security_group.worker.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "worker_ingress_icmp" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id

  protocol    = "icmp"
  cidr_blocks = var.cidr_blocks
  from_port   = -1
  to_port     = -1
}

resource "aws_security_group_rule" "worker_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 22
  to_port     = 22
}

//https://docs.rke2.io/install/requirements/ 
//All nodes need to be able to reach other nodes over UDP port 8472 when Flannel VXLAN is used.
resource "aws_security_group_rule" "worker_ingress_vxlan" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id

  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
  self      = true
}

resource "aws_security_group_rule" "worker_ingress_vxlan_from_master" {
  type                     = "ingress"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.master.id

  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
}

resource "aws_security_group_rule" "worker_ingress_metrics" {
  type              = "ingress"
  security_group_id = aws_security_group.worker.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 10250
  to_port     = 10250
}

resource "aws_security_group_rule" "worker_ingress_nodeport" {
  description       = "NodePort range Ingress"
  type              = "ingress"
  security_group_id = aws_security_group.worker.id

  protocol    = "tcp"
  cidr_blocks = var.cidr_blocks
  from_port   = 30000 
  to_port     = 32767
}

# TODO Calico CNI & Canal CNI