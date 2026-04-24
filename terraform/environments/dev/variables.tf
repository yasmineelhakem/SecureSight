variable "environment" {
  description = "Deployment environment — drives resource naming and behavior"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "tags" {
  description = "Additional tags merged into all resources"
  type        = map(string)
  default     = {}
}

# Networking vars

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# EKS vars

variable "kubernetes_version" {
  description = "Kubernetes version to run on EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Normal number of worker nodes running"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum nodes — floor for scale down"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum nodes — ceiling for scale up"
  type        = number
  default     = 4
}

# Load balancer vars

variable "certificate_arn" {
  description = "ACM certificate ARN — null in dev"
  type        = string
  default     = null
}

# Database Credentials for Secrets Manager
variable "mongodb_username" {
  description = "MongoDB root username (set via TF_VAR_mongodb_username)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_password" {
  description = "MongoDB root password (set via TF_VAR_mongodb_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongodb_uri" {
  description = "MongoDB connection URI (set via TF_VAR_mongodb_uri)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mariadb_root_password" {
  description = "MariaDB root password (set via TF_VAR_mariadb_root_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mariadb_user" {
  description = "MariaDB username (set via TF_VAR_mariadb_user)"
  type        = string
  sensitive   = true
  default     = "root"
}

variable "mariadb_password" {
  description = "MariaDB password (set via TF_VAR_mariadb_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mariadb_database" {
  description = "MariaDB database name"
  type        = string
  default     = "catalogue"
}

variable "redis_password" {
  description = "Redis password (set via TF_VAR_redis_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rabbitmq_username" {
  description = "RabbitMQ username (set via TF_VAR_rabbitmq_username)"
  type        = string
  sensitive   = true
  default     = "guest"
}

variable "rabbitmq_password" {
  description = "RabbitMQ password (set via TF_VAR_rabbitmq_password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ebs_csi_addon_version" {
  description = "EBS CSI driver addon version"
  type        = string
  default     = null
}