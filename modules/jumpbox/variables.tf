variable "ec2_ami" {
  type        = string
  description = "The AMI ID for the jumpbox node."
}

variable "cluster_id" {
  type        = string
  description = "The identifier for the cluster."
}


variable "instance_type" {
  type        = string
  description = "The instance type of the jumpbox node."
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID for the jumpbox node."
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

variable "volume_iops" {
  type        = string
  default     = "100"
  description = "The amount of IOPS to provision for the disk."
}

variable "volume_size" {
  type        = string
  default     = "30"
  description = "The volume size (in gibibytes) for the jumpbox node's root volume."
}

variable "volume_type" {
  type        = string
  default     = "gp2"
  description = "The volume type for the jumpbox node's root volume."
}

variable "volume_kms_key_id" {
  type        = string
  description = "The KMS key id that should be used to encrypt the jumpbox node's root block device."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID is used to create resources like security group rules for jumpbox machine."
}

variable "vpc_cidrs" {
  type        = list(string)
  default     = []
  description = "VPC CIDR blocks."
}

variable "vpc_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Additional VPC security group IDs for the jumpbox node."
}

variable "publish_strategy" {
  type        = string
  description = "The publishing strategy for endpoints like load balancers"
}
variable "aws_key_name" {
  type = string
}



variable "s3_files_location" {

  type = list(object({
    local_path = string,
    s3_path    = string
  }))
  default     = []
  description = "S3 files needed to be downloaded to the jumpbox."
}