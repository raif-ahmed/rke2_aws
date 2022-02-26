locals {
  arn = "aws"
}

data "aws_partition" "current" {}

# https://rancher.com/docs/rancher/v2.5/en/cluster-admin/cluster-autoscaler/amazon/
#
# Role
#
resource "aws_iam_role" "cp_role" {
  name = "${var.cluster_id}-cp-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.${data.aws_partition.current.dns_suffix}",
                    "eks.${data.aws_partition.current.dns_suffix}",
                    "autoscaling.${data.aws_partition.current.dns_suffix}",
                    "elasticloadbalancing.${data.aws_partition.current.dns_suffix}",
                    "kms.${data.aws_partition.current.dns_suffix}",
                    "s3.${data.aws_partition.current.dns_suffix}"
                ]
            }
        }
    ]
}
EOF

  tags = merge(
    {
      "Name" = "${var.cluster_id}-cp-role"
    },
    var.tags,
  )
}

#
# Role Policies, https://rancher.com/docs/rancher/v2.5/en/cluster-admin/cluster-autoscaler/amazon/
# i meged both controlplane role & (etcd or worker) role
resource "aws_iam_role_policy" "k8s_master_profile" {
  name = "${var.cluster_id}-k8s-master-profile"
  role = aws_iam_role.cp_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "iam:CreateServiceLinkedRole",
        "kms:DescribeKey",
        "s3:GetObject"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

}
# Role Policies, https://rancher.com/docs/rancher/v2.5/en/cluster-admin/cluster-autoscaler/amazon/
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md?plain=1#L41-L65
# It is strongly recommended to restrict the target resources for the autoscaling actions by either 
# specifying Auto Scaling Group ARNs in the Resource list of the policy or using tag based conditionals. 
# The minimal policy includes an example of restricting by ASG ARN. I'm not specifying the Auto Scaling Group ARNs
# Most probably the autoscalers will run on masters, so i will attche it to the master.
resource "aws_iam_role_policy" "k8s_autoscaler_profile" {
  count = var.enable_autoscaler_auto_discovery ? 1 : 0
  name  = "${var.cluster_id}-k8s-autoscaler-profile"
  role  = aws_iam_role.cp_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#
# EC2 IAM instance profile, this will be used for controlplan instances (masters)
#
resource "aws_iam_instance_profile" "cp" {
  name = "${var.cluster_id}-cp-profile"

  role = aws_iam_role.cp_role.name
}


#
# Role
#
resource "aws_iam_role" "worker_role" {
  name = "${var.cluster_id}-worker-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                  
                    "ec2.${data.aws_partition.current.dns_suffix}",
                    "s3.${data.aws_partition.current.dns_suffix}"
                ]
            }
        }
    ]
}
EOF

  tags = merge(
    {
      "Name" = "${var.cluster_id}-worker-role"
    },
    var.tags,
  )
}

#
# Role Policies, https://rancher.com/docs/rke/latest/en/config-options/cloud-providers/aws/#iam-requirements 
# Worker
#
resource "aws_iam_role_policy" "k8s_worker_profile" {
  name = "${var.cluster_id}-k8s-worker-profile"
  role = aws_iam_role.worker_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage",
        "s3:GetObject"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

}

#
# EC2 IAM instance profile, this will be used for controlplan instances (masters)
#
resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_id}-worker-profile"

  role = aws_iam_role.worker_role.name
}

