# Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret

# Mongo creds for carts db service
resource "aws_secretsmanager_secret" "carts_db" {
  name                    = "${var.environment}/carts-db"
  description             = "MongoDB credentials for carts service"

  tags = merge(var.tags, {
    Name        = "carts-db-secret"
    Environment = var.environment
    Service     = "carts"
  })
}

resource "aws_secretsmanager_secret_version" "carts_db" {
  secret_id = aws_secretsmanager_secret.carts_db.id
  secret_string = jsonencode({
    MONGO_INITDB_ROOT_USERNAME = var.mongodb_username
    MONGO_INITDB_ROOT_PASSWORD = var.mongodb_password
    SPRING_DATA_MONGODB_URI    = var.mongodb_uri
  })
}

# MariaDB creds for catalogue db service
resource "aws_secretsmanager_secret" "catalogue_db" {
  name                    = "${var.environment}/catalogue-db"
  description             = "MariaDB credentials for catalogue service"

  tags = merge(var.tags, {
    Name        = "catalogue-db-secret"
    Environment = var.environment
    Service     = "catalogue"
  })
}

resource "aws_secretsmanager_secret_version" "catalogue_db" {
  secret_id = aws_secretsmanager_secret.catalogue_db.id
  secret_string = jsonencode({
    MARIADB_ROOT_PASSWORD = var.mariadb_root_password
    MARIADB_USER          = var.mariadb_user
    MARIADB_PASSWORD      = var.mariadb_password
    MARIADB_DATABASE      = var.mariadb_database
  })
}


# Redis creds for session db service
resource "aws_secretsmanager_secret" "session_db" {
  name                    = "${var.environment}/session-db"
  description             = "Redis credentials for session store"

  tags = merge(var.tags, {
    Name        = "session-db-secret"
    Environment = var.environment
    Service     = "session"
  })
}

resource "aws_secretsmanager_secret_version" "session_db" {
  secret_id = aws_secretsmanager_secret.session_db.id
  secret_string = jsonencode({
    REDIS_PASSWORD = var.redis_password
  })
}

# RabbitMQ creds for message broker
resource "aws_secretsmanager_secret" "rabbitmq" {
  name                    = "${var.environment}/rabbitmq"
  description             = "RabbitMQ credentials for message broker"

  tags = merge(var.tags, {
    Name        = "rabbitmq-secret"
    Environment = var.environment
    Service     = "rabbitmq"
  })
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    RABBITMQ_DEFAULT_USER = var.rabbitmq_username
    RABBITMQ_DEFAULT_PASS = var.rabbitmq_password
  })
}