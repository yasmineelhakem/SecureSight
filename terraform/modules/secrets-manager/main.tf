# Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret

# Mongo creds for carts db service
resource "aws_secretsmanager_secret" "carts_db" {
  name        = "${var.environment}/carts-db"
  description = "MongoDB credentials for carts service"

  tags = merge(var.tags, {
    Name        = "carts-db-secret"
    Environment = var.environment
    Service     = "carts"
  })
}

resource "aws_secretsmanager_secret_version" "carts_db" {
  secret_id = aws_secretsmanager_secret.carts_db.id
  secret_string = jsonencode({
    MONGO_INITDB_ROOT_USERNAME = ""
    MONGO_INITDB_ROOT_PASSWORD = ""
    SPRING_DATA_MONGODB_URI    = ""
  })

  lifecycle {
    ignore_changes = [secret_string]  # values managed via CLI not terraform
  }
}

# MariaDB creds for catalogue db service
resource "aws_secretsmanager_secret" "catalogue_db" {
  name        = "${var.environment}/catalogue-db"
  description = "MariaDB credentials for catalogue service"

  tags = merge(var.tags, {
    Name        = "catalogue-db-secret"
    Environment = var.environment
    Service     = "catalogue"
  })
}

resource "aws_secretsmanager_secret_version" "catalogue_db" {
  secret_id = aws_secretsmanager_secret.catalogue_db.id
  secret_string = jsonencode({
    MARIADB_ROOT_PASSWORD = ""
    MARIADB_USER          = ""
    MARIADB_PASSWORD      = ""
    MARIADB_DATABASE      = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Redis creds for session db service
resource "aws_secretsmanager_secret" "session_db" {
  name        = "${var.environment}/session-db"
  description = "Redis credentials for session store"

  tags = merge(var.tags, {
    Name        = "session-db-secret"
    Environment = var.environment
    Service     = "session"
  })
}

resource "aws_secretsmanager_secret_version" "session_db" {
  secret_id = aws_secretsmanager_secret.session_db.id
  secret_string = jsonencode({
    REDIS_PASSWORD = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# RabbitMQ creds for message broker
resource "aws_secretsmanager_secret" "rabbitmq" {
  name        = "${var.environment}/rabbitmq"
  description = "RabbitMQ credentials for message broker"

  tags = merge(var.tags, {
    Name        = "rabbitmq-secret"
    Environment = var.environment
    Service     = "rabbitmq"
  })
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    RABBITMQ_DEFAULT_USER = ""
    RABBITMQ_DEFAULT_PASS = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}