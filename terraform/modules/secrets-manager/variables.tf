variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
