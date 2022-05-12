locals {
  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  # https://rancher.com/docs/rke/latest/en/config-options/cloud-providers/aws/
  tags = merge(
    {
      "kubernetes.io/cluster/${var.cluster_id}" = "owned"
    },
    var.aws_extra_tags,
  )
}


module "vpc" {
  source = "./modules/vpc"

  cidr_blocks        = [var.machine_cidr]
  vpc_id             = var.cluster_id
  region             = var.aws_region
  vpc                = var.aws_vpc
  public_subnets     = var.aws_public_subnets
  private_subnets    = var.aws_private_subnets
  publish_strategy   = var.aws_publish_strategy
  airgapped          = var.airgapped
  availability_zones = data.aws_availability_zones.aws_azs.names

  //https://docs.rke2.io/install/requirements/ 
  //All nodes need to be able to reach other nodes over CNI VXLAN.
  cni_ingress_rules = [
    { from_port : 8472, to_port : 8472, protocol : "UDP", description : "Required for Flannel,Cilium,Canal CNI VXLAN" },

    { from_port : 4240, to_port : 4240, protocol : "TCP", description : "Cilium CNI health checks" },
    { from_port : 8, to_port : 0, protocol : "ICMP", description : "Cilium CNI health checks" },

    { from_port : 179, to_port : 179, protocol : "TCP", description : "Calico CNI with BGP" },
    { from_port : 4789, to_port : 4789, protocol : "UDP", description : "Calico CNI with VXLAN" },
    { from_port : 5473, to_port : 5473, protocol : "TCP", description : "Calico CNI with Typha" },

    { from_port : 9099, to_port : 9099, protocol : "TCP", description : "Canal CNI health checks" },
    { from_port : 51820, to_port : 51820, protocol : "UDP", description : "Canal CNI with WireGuard IPv4" },
    { from_port : 51821, to_port : 51821, protocol : "UDP", description : "Canal CNI with WireGuard IPv6/dual-stack" }
  ]

  tags = local.tags
}

module "iam" {
  source = "./modules/iam"

  cluster_id                       = var.cluster_id
  tags                             = local.tags
  enable_autoscaler_auto_discovery = var.enable_autoscaler_auto_discovery
}
# normally the files i want on any machine i will upload them to s3, 
# then download them from s3 during cloud-init
module "jumpbox_s3" {
  source = "./modules/s3"

  bucket_create   = true
  bucket_name     = format("%s-%s", var.cluster_id, "jumpbox")
  bucket_contents = [{ "key" = "id_rsa", "local_path" = "/home/ubuntu/.ssh/id_rsa", "content_base64" = "${base64encode(tls_private_key.ssh_key.private_key_pem)}" }]

  tags = local.tags
}
module "jumpbox" {
  source = "./modules/jumpbox"

  ec2_ami                    = local.ec2_jumpbox_ami.image_id
  instance_type              = var.aws_jumpbox_instance_type
  cluster_id                 = var.cluster_id
  aws_key_name               = aws_key_pair.ssh_key.key_name
  subnet_id                  = var.aws_publish_strategy == "External" ? module.vpc.az_to_public_subnet_id[data.aws_availability_zones.aws_azs.names[0]] : module.vpc.az_to_private_subnet_id[data.aws_availability_zones.aws_azs.names[0]]
  target_group_arns          = module.vpc.aws_lb_target_group_arns
  target_group_arns_length   = module.vpc.aws_lb_target_group_arns_length
  vpc_id                     = module.vpc.vpc_id
  vpc_cidrs                  = module.vpc.vpc_cidrs
  volume_kms_key_id          = var.aws_root_volume_kms_key_id
  publish_strategy           = var.aws_publish_strategy
  download_files_from_bucket = true
  bucket_name                = module.jumpbox_s3.bucket_name
  bucket_objects             = module.jumpbox_s3.bucket_objects

  tags = local.tags
}
module "masters" {
  source = "./modules/nodes"

  cluster_id    = var.cluster_id
  instance_type = var.aws_master_instance_type

  tags = local.tags

  availability_zones            = data.aws_availability_zones.aws_azs.names
  az_to_subnet_id               = module.vpc.az_to_private_subnet_id
  instance_count                = length(data.aws_availability_zones.aws_azs.names)
  ec2_sg_ids                    = [module.vpc.master_sg_id]
  node_type                     = "master"
  aws_iam_instance_profile_name = module.iam.master_instance_profile_name
  aws_key_name                  = aws_key_pair.ssh_key.key_name
  root_volume_iops              = var.aws_master_root_volume_iops
  root_volume_size              = var.aws_master_root_volume_size
  root_volume_type              = var.aws_master_root_volume_type
  root_volume_encrypted         = var.aws_master_root_volume_encrypted
  root_volume_kms_key_id        = var.aws_root_volume_kms_key_id
  target_group_arns             = module.vpc.aws_lb_target_group_arns
  target_group_arns_length      = module.vpc.aws_lb_target_group_arns_length
  ec2_ami                       = local.ec2_master_ami.image_id
  user_data                     = ""
  publish_strategy              = var.aws_publish_strategy
}

# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws
# https://rancher.com/docs/rancher/v2.5/en/cluster-admin/cluster-autoscaler/
# On AWS, Cluster Autoscaler utilizes Amazon EC2 Auto Scaling Groups to manage node groups.
# So we have two way, automatic and manual
# 1. for Full Cluster Autoscaler Features Policy (automatic), it should be enabled in the iam module. 
# This will allow cluster-autoscaler to discover asg tagged with "k8s.io/cluster-autoscaler/enabled"
# 2. for Static Instance List (Manual) Autoscaler Features Policy, nodepool module try to create an ASG to be used with the auto scaler deployment. 

module "nodetemplate" {
  source = "./modules/nodetemplate"
  # I want to have an ASG in each AZ (private subnet)
  count = var.autoscaler_nodetemplate_count

  cluster_id    = var.cluster_id
  instance_type = var.aws_worker_instance_type


  tags = var.enable_autoscaler_auto_discovery ? merge(
    {
      "k8s.io/cluster-autoscaler/enabled"           = "",
      "k8s.io/cluster-autoscaler/${var.cluster_id}" = ""
    },
    local.tags,
  ) : local.tags

  pool_name                     = "worker-${count.index}"
  ec2_sg_ids                    = [module.vpc.worker_sg_id]
  aws_iam_instance_profile_name = module.iam.worker_instance_profile_name
  # subnet_id                   = module.vpc.private_subnet_ids[count.index]
  subnet_id                = module.vpc.az_to_private_subnet_id[data.aws_availability_zones.aws_azs.names[(count.index % length(data.aws_availability_zones.aws_azs.names))]]
  aws_key_name             = aws_key_pair.ssh_key.key_name
  root_volume_iops         = var.aws_worker_root_volume_iops
  root_volume_size         = var.aws_worker_root_volume_size
  root_volume_type         = var.aws_worker_root_volume_type
  root_volume_encrypted    = var.aws_worker_root_volume_encrypted
  root_volume_kms_key_id   = var.aws_root_volume_kms_key_id
  target_group_arns        = module.vpc.aws_lb_target_group_arns
  target_group_arns_length = module.vpc.aws_lb_target_group_arns_length
  ec2_ami                  = local.ec2_worker_ami.image_id
  user_data                = ""
  asg                      = { min = 0, max = 5, desired = 0 }
  use_spot                 = false
}

module "dns" {
  source = "./modules/route53"

  api_external_lb_dns_name = module.vpc.aws_lb_api_external_dns_name
  api_external_lb_zone_id  = module.vpc.aws_lb_api_external_zone_id
  api_internal_lb_dns_name = module.vpc.aws_lb_api_internal_dns_name
  api_internal_lb_zone_id  = module.vpc.aws_lb_api_internal_zone_id
  base_domain              = var.base_domain
  cluster_domain           = "${var.cluster_id}.${var.base_domain}"
  cluster_id               = var.cluster_id
  tags                     = local.tags
  vpc_id                   = module.vpc.vpc_id
  region                   = var.aws_region
  publish_strategy         = var.aws_publish_strategy
  is_public_zone_exists    = var.is_public_zone_exists
}