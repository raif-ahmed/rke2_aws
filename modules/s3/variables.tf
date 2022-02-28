variable "bucket_create" {
  type        = bool
  description = "Create a new Bucket or bucket already exists and object will be added there ."
}
variable "bucket_name" {
  type        = string
  description = "Bucket Name."
}

variable "bucket_contents" {

  type = list(object({
    key            = string,
    content_base64 = string
  }))
  description = "Bucket Contents."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}