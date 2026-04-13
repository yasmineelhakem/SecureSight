
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB — from subnets module"
  type        = list(string)
}

variable "lb_security_group_id" {
  description = "Security group ID for ALB — from nsg module"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS — required in prod, null in dev"
  type        = string
  default     = null   
}


variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}