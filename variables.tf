variable "aws_config_version" {
  description = <<EOF
(internal) This declares the version of the AWS configuration variables.
It has no impact on generated assets but declares the version contract of the configuration.
EOF

  default = "1.0"
}

variable "aws_jumpbox_instance_type" {
  type        = string
  description = "Instance type for the jumpbox node. Default: `i3.xlarge`."
  default     = "t3.medium"
}

variable "aws_master_instance_type" {
  type        = string
  description = "Instance type for the master node(s). Default: `m4.xlarge`."
  default     = "m5.xlarge"
}

variable "aws_worker_instance_type" {
  type        = string
  description = "Instance type for the worker node(s). Default: `m4.2xlarge`."
  default     = "m5.2xlarge"
}

# variable "aws_ami" {
#   type        = string
#   description = "AMI for all nodes.  An encrypted copy of this AMI will be used.  Example: `ami-foobar123`."
# }

variable "aws_extra_tags" {
  type = map(string)

  description = <<EOF
(optional) Extra AWS tags to be applied to created resources.

Example: `{ "owner" = "me", "kubernetes.io/cluster/mycluster" = "owned" }`
EOF

  default = {}
}

variable "aws_master_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of master nodes."
  default     = "gp2"
}

variable "aws_master_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default     = 200
}

variable "aws_master_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of master nodes.
Ignored if the volume type is not io1.
EOF
  default     = 0

}

variable "aws_worker_root_volume_type" {
  type        = string
  description = "The type of volume for the root block device of worker nodes."
  default     = "gp2"
}

variable "aws_worker_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of worker nodes."
  default     = 200
}

variable "aws_worker_root_volume_iops" {
  type = string

  description = <<EOF
The amount of provisioned IOPS for the root block device of worker nodes.
Ignored if the volume type is not io1.
EOF
  default     = 0

}
variable "aws_worker_root_volume_encrypted" {
  type        = bool
  default     = true
  description = <<EOF
Indicates whether the root EBS volume for workers is encrypted. Encrypted Amazon EBS volumes
may only be attached to machines that support Amazon EBS encryption.
EOF

}

variable "aws_master_root_volume_encrypted" {
  type        = bool
  default     = true
  description = <<EOF
Indicates whether the root EBS volume for master is encrypted. Encrypted Amazon EBS volumes
may only be attached to machines that support Amazon EBS encryption.
EOF

}

variable "aws_root_volume_kms_key_id" {
  type = string

  description = <<EOF
(optional) Indicates the KMS key that should be used to encrypt the Amazon EBS volume.
If not set and root volume has to be encrypted, the default KMS key for the account will be used.
EOF

  default = ""
}

variable "aws_region" {
  type        = string
  description = "The target AWS region for the cluster."
}

variable "aws_azs" {
  type        = list(string)
  description = "The availability zones in which to create the nodes."
  default     = null
}

variable "aws_vpc" {
  type        = string
  default     = null
  description = "(optional) An existing network (VPC ID) into which the cluster should be installed."
}

variable "aws_public_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing public subnets into which the cluster should be installed."
}

variable "aws_private_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing private subnets into which the cluster should be installed."
}

variable "aws_publish_strategy" {
  type        = string
  description = "The cluster publishing strategy, either Internal or External"
  default     = "External"
}

variable "aws_publish_jumbbox" {
  type        = string
  description = "The cluster publishing strategy, either Internal or External"
  # default     = "Internal"
  default     = "External"
}

variable "is_public_zone_exists" {
  description = "In the public zone already exists and no need to create it"
  type        = bool
}

variable "aws_skip_region_validation" {
  type        = bool
  default     = false
  description = "This decides if the AWS provider should validate if the region is known."
}

# https://rancher.com/docs/rke/latest/en/config-options/cloud-providers/aws/
# https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
# https://azure.github.io/PSRule.Rules.Azure/en/rules/Azure.AKS.Name/
variable "cluster_id" {
  type        = string
  description = "An ID we will use to tag all the generated resources to correlate them with this specific deployment"

  validation {
    # many names depends on cluster_id so we need to honor the max length limitations
    condition     = length(var.cluster_id) > 1 && length(var.cluster_id) < 12
    error_message = "Cluster name should be Between 1 and 12 characters long."
  }
  validation {
    condition     = can(regex("[a-zA-Z0-9-\\-]+", var.cluster_id))
    error_message = "Cluster name can only be Alphanumerics and hyphens."
  }

}

variable "machine_cidr" {
  type        = string
  description = <<EOF
The IP address space from which to assign machine IPs.
Default "10.0.0.0/16"
EOF
  default     = "10.0.0.0/16"
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled    = false
    repository = ""
  }
}

variable "base_domain" {
  description = "The base domain used for public records."
  type        = string
}

variable "enable_autoscaler_auto_discovery" {
  type        = bool
  default     = true
  description = "Toggle configure for cluster autoscaler Auto Discovery, this will ensure the appropriate IAM policies are present, you are still responsible for ensuring cluster autoscaler is installed"
}

variable "autoscaler_nodetemplate_count" {
  type        = number
  description = "The number of ASG to create for the cluster autoscaler"
}


# variable "aws_access_key_id" {
#   type        = string
#   description = "AWS Key"
# }

# variable "aws_secret_access_key" {
#   type        = string
#   description = "AWS Secret"
# }
