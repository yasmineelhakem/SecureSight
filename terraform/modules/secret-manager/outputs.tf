output "carts_db_secret_arn" {
  description = "ARN of carts-db secret"
  value       = aws_secretsmanager_secret.carts_db.arn
}

output "carts_db_secret_id" {
  description = "ID of carts-db secret"
  value       = aws_secretsmanager_secret.carts_db.id
}

output "catalogue_db_secret_arn" {
  description = "ARN of catalogue-db secret"
  value       = aws_secretsmanager_secret.catalogue_db.arn
}

output "catalogue_db_secret_id" {
  description = "ID of catalogue-db secret"
  value       = aws_secretsmanager_secret.catalogue_db.id
}

output "session_db_secret_arn" {
  description = "ARN of session-db secret"
  value       = aws_secretsmanager_secret.session_db.arn
}

output "session_db_secret_id" {
  description = "ID of session-db secret"
  value       = aws_secretsmanager_secret.session_db.id
}

output "rabbitmq_secret_arn" {
  description = "ARN of rabbitmq secret"
  value       = aws_secretsmanager_secret.rabbitmq.arn
}

output "rabbitmq_secret_id" {
  description = "ID of rabbitmq secret"
  value       = aws_secretsmanager_secret.rabbitmq.id
}

output "all_secret_arns" {
  description = "Map of all secret names to their ARNs"
  value = {
    carts_db    = aws_secretsmanager_secret.carts_db.arn
    catalogue_db = aws_secretsmanager_secret.catalogue_db.arn
    session_db  = aws_secretsmanager_secret.session_db.arn
    rabbitmq    = aws_secretsmanager_secret.rabbitmq.arn
  }
}
