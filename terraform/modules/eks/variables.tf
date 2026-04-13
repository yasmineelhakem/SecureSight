variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for LB discovery"
  type        = list(string)
}

variable "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS cluster — from iam module"
  type        = string
}

variable "eks_node_role_arn" {
  description = "IAM role ARN for EKS nodes — from iam module"
  type        = string
}

variable "eks_nodes_sg_id" {
  description = "Security group ID for EKS nodes — from nsg module"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"   
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}