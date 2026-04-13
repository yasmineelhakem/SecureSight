# Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
# https://registry.terraform.io/providers/-/aws/6.8.0/docs/resources/lb_target_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
# lb = alb

resource "aws_lb" "main" {
  name               = "alb-${var.environment}"
  internal           = false         
  load_balancer_type = "application"  
  security_groups    = [var.lb_security_group_id]
  subnets            = var.public_subnet_ids  # alb un public subnet

  # can't be deleted via the aws api in prod
  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(var.tags, {
    Name = "alb-${var.environment}"
  })
}


resource "aws_lb_target_group" "main" {
  name        = "tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"   

  tags = merge(var.tags, {
    Name = "tg-${var.environment}"
  })
}

resource "aws_lb_listener" "http_dev" {
  count             = var.environment == "dev" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name = "listener-http-dev"
  })
}

# http listener redirects to HTTPS 
resource "aws_lb_listener" "http_prod" {
  count             = var.environment == "prod" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" 
    }
  }

  tags = merge(var.tags, {
    Name = "listener-http-prod"
  })
}

# https listener forwards traffic to target group 
# only in prod env because it requires a valid certificate which we may not have for dev
resource "aws_lb_listener" "https" {
  count             = var.environment == "prod" && var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" 
  certificate_arn   = var.certificate_arn   # should have a doamin

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name = "listener-https-prod"
  })
}