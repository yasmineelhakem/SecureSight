variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "addon_version" {
  description = "EBS CSI driver addon version"
  type        = string
  default     = null  # Uses latest if not specified
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}