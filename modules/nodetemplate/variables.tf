variable "cluster_id" {
  type = string
}

variable "ec2_sg_ids" {
  type        = list(string)
  description = "The security group IDs to be applied to the ec2 instance."
}


variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which to create the asg."
}




variable "root_volume_iops" {
  type        = string
  description = "The amount of provisioned IOPS for the root block device."
}

variable "root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device."
}

variable "root_volume_type" {
  type        = string
  description = "The type of volume for the root block device."
}

variable "root_volume_encrypted" {
  type        = bool
  default     = true
  description = "Whether the root block device should be encrypted."
}

variable "root_volume_kms_key_id" {
  type        = string
  description = "The KMS key id that should be used tpo encrypt the root block device."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "target_group_arns" {
  type        = list(string)
  default     = []
  description = "The list of target group ARNs for the load balancer."
}

variable "target_group_arns_length" {
  description = "The length of the 'target_group_arns' variable, to work around https://github.com/hashicorp/terraform/issues/12570."
}

variable "user_data" {
  type = string
}

variable "asg" {
  type = object({
    min     = number
    max     = number
    desired = number
  })
}

variable "ec2_ami" {
  type    = string
  default = ""
}

# variable "min_elb_capacity" {
#   type    = number
#   default = null
# }

variable "instance_type" {
  type        = string
  description = "The instance type to be identified in the ec2 name, it can be either master or agent."
}

variable "aws_iam_instance_profile_name" {
  type = string
}

variable "aws_key_name" {
  type = string
}

variable "pool_name" {
  type = string
  validation {
    condition     = length(var.pool_name) > 1 && length(var.pool_name) < 12
    error_message = "Pool name should be Between 1 and 12 characters long."
  }
  validation {
    condition     = can(regex("[a-zA-Z0-9-\\-]+", var.pool_name))
    error_message = "Pool name can only be Alphanumerics and hyphens."
  }
}

variable "launch_template_to_id" {
  type        = map(string)
  description = "Map from launch template name to the ID"
  default     = {}
}

variable "lb_port" {
  type        = list(string)
  description = "list of ports for the ALB"
  default     = ["80", "443"]
}
variable "lb_port_to_protocol" {
  type        = map(string)
  description = "Map from port to the for protocol the ALB"
  default     = { "80" = "HTTP", "443" = "HTTPS" }
}

variable "use_spot" {
  type        = bool
  default     = true
  description = "Whether use Spot-Requests/MixedInstancesPolicy or use only On-Demand Instances"
}
# variable "publish_strategy" {
#   type        = string
#   description = <<EOF
# The publishing strategy for endpoints like load balancers.

# Because of the issue https://github.com/hashicorp/terraform/issues/12570, the consumers cannot use a dynamic list for count
# and therefore are force to implicitly assume that the list is of aws_lb_target_group_arns_length - 1, in case there is no api_external. And that's where this variable
# helps to decide if the target_group_arns is of length (target_group_arns_length) or (target_group_arns_length - 1)
# EOF
# }
# variable "target_group_arns" {
#   type        = list(string)
#   default     = []
#   description = "The list of target group ARNs for the load balancer."
# }

# variable "target_group_arns_length" {
#   description = "The length of the 'target_group_arns' variable, to work around https://github.com/hashicorp/terraform/issues/12570."
# }