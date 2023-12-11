output "bucket_name" {
  value = var.bucket_create ? aws_s3_bucket.this_bucket[0].bucket : data.aws_s3_bucket.this_bucket[0].bucket

}
output "bucket_objects" {
  value = aws_s3_object.this_bucket_object.*

}
