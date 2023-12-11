variable "masters_ip" {
  type        = list(object({
    node_name = string
    node_ip = string
    node_external_ip = string
    node_labels = list(string)
    node_taints = list(string)
  }))
  description = "List of Masters IPs ."
}
variable "bucket_name" {
  type        = string
  description = "Bucket Name."
}

variable "bucket_contents" {

  type = list(object({
    key            = string,
    content_base64 = string,
    local_path     = string
  }))
  description = "Bucket Contents."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}