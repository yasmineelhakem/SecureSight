variable "cluster_name" {
  description = "EKS cluster name"
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

variable "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI Driver (for IRSA)"
  type = string
}