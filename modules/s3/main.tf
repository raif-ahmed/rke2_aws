locals {
  this_bucket = var.bucket_create ? aws_s3_bucket.this_bucket : data.aws_s3_bucket.this_bucket

}

data "aws_region" "current" {}

data "aws_s3_bucket" "this_bucket" {
  count = var.bucket_create ? 0 : 1

  bucket = var.bucket_name
  # region = data.aws_region.current.name
}

resource "aws_s3_bucket" "this_bucket" {
  count = var.bucket_create ? 1 : 0

  bucket_prefix = "${var.bucket_name}-"
  tags = merge(
    {
      "Name" = "${var.bucket_name}"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_acl" "this_bucket_acl" {
  count  = var.bucket_create ? 1 : 0
  bucket = aws_s3_bucket.this_bucket[count.index].id
  acl    = "private"
}


resource "aws_s3_object" "this_bucket_object" {

  count = length(var.bucket_contents)

  bucket         = local.this_bucket[0].id
  key            = var.bucket_contents[count.index].key
  content_base64 = var.bucket_contents[count.index].content_base64
  acl            = "private"

  server_side_encryption = "AES256"

  tags = merge(
    {
      "Name" = "${var.bucket_contents[count.index].key}"
    },
    var.tags,
  )

  lifecycle {
    ignore_changes = all
  }
}


