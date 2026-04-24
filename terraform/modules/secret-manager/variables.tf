variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

# MongoDB Credentials
variable "mongodb_username" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
  default     = "carts"
}

variable "mongodb_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
}

# MariaDB Credentials
variable "mariadb_root_password" {
  description = "MariaDB root password"
  type        = string
  sensitive   = true
}

variable "mariadb_user" {
  description = "MariaDB username"
  type        = string
  sensitive   = true
  default     = "root"
}

variable "mariadb_password" {
  description = "MariaDB password"
  type        = string
  sensitive   = true
}

variable "mariadb_database" {
  description = "MariaDB database name"
  type        = string
  default     = "catalogue"
}

# Redis Credentials
variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

# RabbitMQ Credentials
variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  sensitive   = true
  default     = "guest"
}

variable "rabbitmq_password" {
  description = "RabbitMQ password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
