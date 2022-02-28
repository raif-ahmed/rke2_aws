locals {
  public_endpoints = var.publish_strategy == "External" ? true : false
}



data "aws_partition" "current" {}

data "aws_ebs_default_kms_key" "current" {}

resource "aws_iam_instance_profile" "jumpbox" {
  name = "${var.cluster_id}-jumpbox-profile"

  role = aws_iam_role.jumpbox.name
}

resource "aws_iam_role" "jumpbox" {
  name = "${var.cluster_id}-jumpbox-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.${data.aws_partition.current.dns_suffix}"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = merge(
    {
      "Name" = "${var.cluster_id}-jumpbox-role"
    },
    var.tags,
  )
}

resource "aws_iam_role_policy" "jumpbox" {
  name = "${var.cluster_id}-jumpbox-policy"
  role = aws_iam_role.jumpbox.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    },
    {
      "Action" : [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::*",
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_security_group" "jumpbox" {
  vpc_id = var.vpc_id

  timeouts {
    create = "20m"
  }

  tags = merge(
    {
      "Name" = "${var.cluster_id}-jumpbox-sg"
    },
    var.tags,
  )
}

resource "aws_security_group_rule" "ingress_icmp" {
  type              = "ingress"
  security_group_id = aws_security_group.jumpbox.id

  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = -1
  to_port     = -1
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.jumpbox.id

  protocol    = "tcp"
  cidr_blocks = local.public_endpoints ? ["0.0.0.0/0"] : var.vpc_cidrs
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  security_group_id = aws_security_group.jumpbox.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# i will need two files, the cloud-init & the bash to connect to s3
data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud-init.yaml")
}

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init.rendered
  }

  part {
    filename     = "00_download_s3.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/download_s3.tftpl", {
      s3_files_location = var.s3_files_location
    })
  }

}

resource "aws_instance" "jumpbox" {
  ami = var.ec2_ami

  iam_instance_profile        = aws_iam_instance_profile.jumpbox.name
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = flatten([var.vpc_security_group_ids, aws_security_group.jumpbox.id])
  associate_public_ip_address = local.public_endpoints
  key_name                    = var.aws_key_name
  user_data                   = data.template_cloudinit_config.config.rendered


  lifecycle {
    # Ignore changes in the AMI which force recreation of the resource. This
    # avoids accidental deletion of nodes whenever a new OS release comes out.
    ignore_changes = [ami]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_id}-jumpbox"
    },
    var.tags,
  )

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size
    iops        = var.volume_type == "io1" ? var.volume_iops : 0
    encrypted   = true
    kms_key_id  = var.volume_kms_key_id == "" ? data.aws_ebs_default_kms_key.current.key_arn : var.volume_kms_key_id
  }

  volume_tags = merge(
    {
      "Name" = "${var.cluster_id}-jumpbox-vol"
    },
    var.tags,
  )
}





