resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge({
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }, var.tags)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name        = "igw-${var.environment}"
    Environment = var.environment
  }, var.tags)
}