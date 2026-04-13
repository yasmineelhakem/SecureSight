output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the ALB — used for Route53 alias records"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "https_listener_arn" {
  description = "ARN of HTTPS listener — null in dev"
  value       = var.environment == "prod" ? aws_lb_listener.https[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of HTTP listener"
  value       = var.environment == "dev" ? aws_lb_listener.http_dev[0].arn : aws_lb_listener.http_prod[0].arn
}