locals {
  arn = "aws"

  target_group_arns_length = var.publish_strategy == "External" ? var.target_group_arns_length : var.target_group_arns_length - 1
  public_endpoints         = var.publish_strategy == "External" ? true : false
}

data "aws_partition" "current" {}

data "aws_ebs_default_kms_key" "current" {}

# Dynamically generate multi-part cloud-init configs for each instance index
data "cloudinit_config" "config" {
  count         = var.execute_cloud_init ? var.instance_count : 0
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    # Resolves to templates/cloud-init-<count.index>-<var.node_type>
    content      = templatefile("${path.module}/templates/cloud-init-${count.index}-${var.node_type}.tftpl", {})
  }
}

resource "aws_network_interface" "ec2" {
  count     = var.instance_count
  subnet_id = var.az_to_subnet_id[var.availability_zones[count.index]]

  security_groups = var.ec2_sg_ids

  tags = merge(
    {
      "Name" = "${var.cluster_id}-${var.node_type}-${count.index}"
    },
    var.tags,
  )
}

resource "aws_instance" "ec2" {
  count = var.instance_count
  ami   = var.ec2_ami

  iam_instance_profile = var.aws_iam_instance_profile_name
  instance_type        = var.instance_type
  key_name             = var.aws_key_name

  # Fallback to var.user_data if var.execute_cloud_init is false
  user_data_base64 = var.execute_cloud_init ? data.cloudinit_config.config[count.index].rendered : null
  user_data        = var.execute_cloud_init ? null : var.user_data

  network_interface {
    network_interface_id = aws_network_interface.ec2[count.index].id
    device_index         = 0
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(
    {
      "Name" = "${var.cluster_id}-${var.node_type}-${count.index}"
    },
    var.tags,
  )

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    iops        = var.root_volume_type == "io1" ? var.root_volume_iops : 0
    encrypted   = var.root_volume_encrypted
    kms_key_id  = var.root_volume_kms_key_id == "" ? data.aws_ebs_default_kms_key.current.key_arn : var.root_volume_kms_key_id
  }

  volume_tags = merge(
    {
      "Name" = "${var.cluster_id}-${var.node_type}-${count.index}-vol"
    },
    var.tags,
  )
}

resource "aws_lb_target_group_attachment" "ec2" {
  count = var.instance_count * local.target_group_arns_length

  target_group_arn = var.target_group_arns[count.index % local.target_group_arns_length]
  target_id        = aws_instance.ec2[floor(count.index / local.target_group_arns_length)].private_ip
}

# 1. Internal HTTPS Attachment
resource "aws_lb_target_group_attachment" "ingress_internal_https" {
  count            = length(aws_instance.ec2)
  target_group_arn = var.target_group_arn_internal_https
  target_id        = aws_instance.ec2[count.index].private_ip
  port             = 443
}

# 2. Internal HTTP Attachment
resource "aws_lb_target_group_attachment" "ingress_internal_http" {
  count            = length(aws_instance.ec2)
  target_group_arn = var.target_group_arn_internal_http
  target_id        = aws_instance.ec2[count.index].private_ip
  port             = 80
}

# 3. External HTTPS Attachment
resource "aws_lb_target_group_attachment" "ingress_external_https" {
  count            = local.public_endpoints ? length(aws_instance.ec2) : 0
  target_group_arn = var.target_group_arn_external_https
  target_id        = aws_instance.ec2[count.index].private_ip
  port             = 443
}

# 4. External HTTP Attachment
resource "aws_lb_target_group_attachment" "ingress_external_http" {
  count            = local.public_endpoints ? length(aws_instance.ec2) : 0
  target_group_arn = var.target_group_arn_external_http
  target_id        = aws_instance.ec2[count.index].private_ip
  port             = 80
}