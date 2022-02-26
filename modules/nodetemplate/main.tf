locals {
  arn = "aws"

  launch_template_to_id = var.launch_template_to_id

  // Because of the issue https://github.com/hashicorp/terraform/issues/12570, the consumers cannot use a dynamic list for count
  // and therefore are force to implicitly assume that the list is of aws_lb_target_group_arns_length - 1, in case there is no api_external
  # target_group_arns_length = var.publish_strategy == "External" ? var.target_group_arns_length : var.target_group_arns_length - 1
}

data "aws_partition" "current" {}

data "aws_ebs_default_kms_key" "current" {}

data "aws_kms_key" "current" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
}

#
# Launch template
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/MixedInstancePolicy.md
resource "aws_launch_template" "lnchtmpl" {
  name          = "${var.cluster_id}-${var.pool_name}-lnchtmpl"
  image_id      = var.ec2_ami
  instance_type = var.instance_type
  user_data     = var.user_data
  key_name      = var.aws_key_name


  vpc_security_group_ids = var.ec2_sg_ids

  tags = merge(
    {
      "Name" = "${var.cluster_id}-${var.pool_name}-lnchtmpl"
    },
    var.tags,
  )

  iam_instance_profile {
    name = var.aws_iam_instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type = var.root_volume_type
      volume_size = var.root_volume_size
      iops        = var.root_volume_type == "io1" ? var.root_volume_iops : 0
      encrypted   = var.root_volume_encrypted
      kms_key_id  = var.root_volume_kms_key_id == "" ? data.aws_kms_key.current.arn : var.root_volume_kms_key_id

    }
  }
}

#
# Autoscaling group
#
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/MixedInstancePolicy.md
resource "aws_autoscaling_group" "asg" {
  name                = "${var.cluster_id}-${var.pool_name}-asg"
  vpc_zone_identifier = [var.subnet_id]

  min_size         = var.asg.min
  max_size         = var.asg.max
  desired_capacity = var.asg.desired

  # Health check and target groups can be useful to deploy ingress controller in HA
  # health_check_type = var.health_check_type
  # target_group_arns = var.target_group_arns
  # load_balancers    = var.load_balancers

  # min_elb_capacity = var.min_elb_capacity


  dynamic "launch_template" {
    for_each = var.use_spot ? [] : ["spot"]

    content {
      id      = aws_launch_template.lnchtmpl.id
      version = "$Latest"
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.use_spot ? ["spot"] : []

    content {
      instances_distribution {
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 0
      }

      launch_template {
        launch_template_specification {
          launch_template_id   = aws_launch_template.lnchtmpl.id
          launch_template_name = aws_launch_template.lnchtmpl.name
          version              = "$Latest"
        }
      }
    }
  }

  # Cluster Autoscaler supports hints that nodes will be labelled when they join the cluster via ASG tags. 
  # There is a big list of ASG tags that can be found at
  # https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md?plain=1#L186-L230
  dynamic "tag" {
    for_each = merge({
      "Name" = "${var.cluster_id}-${var.pool_name}-asg"
    }, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}