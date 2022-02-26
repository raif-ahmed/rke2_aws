locals {
  public_endpoints = var.publish_strategy == "External" ? true : false
}


data "aws_partition" "current" {}

data "aws_ebs_default_kms_key" "current" {}

resource "aws_s3_bucket" "this_bucket" {
  acl = "private"

  tags = merge(
    {
      "Name" = "${var.cluster_id}-bootstrap"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_object" "this_bucket_object" {
  bucket  = aws_s3_bucket.this_bucket.id
  key     = "bootstrap.ign"
  content = var.ignition
  acl     = "private"

  server_side_encryption = "AES256"

  tags = merge(
    {
      "Name" = "${var.cluster_id}-bootstrap"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = all
  }
}


