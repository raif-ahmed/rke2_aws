variable "cluster_id" {
  type = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "enable_autoscaler_auto_discovery" {
  type        = bool
  description = "Toggle configure for cluster autoscaler Auto Discovery, this will ensure the appropriate IAM policies are present, you are still responsible for ensuring cluster autoscaler is installed"
}


