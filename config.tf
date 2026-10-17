terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
  # region = "eu-west-1"

  skip_region_validation = var.aws_skip_region_validation

}

locals {
  ec2_master_ami  = data.aws_ami.sles
  ec2_jumpbox_ami = data.aws_ami.ubuntu
  ec2_worker_ami  = data.aws_ami.sles
  # ec2_ami = data.aws_ami.ubuntu
}

# Private Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "${var.cluster_id}-key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.cluster_id}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

data "aws_availability_zones" "aws_azs" {
  state = "available"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-04df7d76c1b804451"]
  }

  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }

  # filter {
  #   name   = "architecture"
  #   values = ["x86_64"]
  # }

  owners = ["099720109477"] # Canonical official
}

# Use latest SLES 15 SP3
data "aws_ami" "sles" {
  most_recent = true
  owners      = ["013907871322"] # SUSE

  filter {
    name   = "image-id"
    # values = ["ami-0d2945b6b30408829"] # SLES 16
    values = ["ami-0affda52580913356"] # SLES 15 SP7
  }

  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }

  # filter {
  #   name   = "architecture"
  #   values = ["x86_64"]
  # }

  # filter {
  #   name   = "root-device-type"
  #   values = ["ebs"]
  # }
}

# data "aws_ami" "windows" {
#   most_recent = true
#   owners      = ["801119661308"] #Amazon
#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Full-ContainersLatest-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

# }

