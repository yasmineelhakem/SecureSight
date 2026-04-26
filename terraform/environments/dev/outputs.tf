# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

# Subnet Outputs
output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.subnets.nat_gateway_id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP"
  value       = module.subnets.nat_gateway_ip
}

# EKS Cluster Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64 encoded)"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}


# IAM Role Outputs
output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = module.iam.eks_node_role_arn
}

output "external_secrets_role_arn" {
  description = "External Secrets IAM role ARN"
  value       = module.irsa.external_secrets_role_arn
}

# Secrets Manager Outputs
output "carts_db_secret_arn" {
  description = "Carts DB secret ARN"
  value       = module.secrets-manager.carts_db_secret_arn
}

output "catalogue_db_secret_arn" {
  description = "Catalogue DB secret ARN"
  value       = module.secrets-manager.catalogue_db_secret_arn
}

output "session_db_secret_arn" {
  description = "Session DB secret ARN"
  value       = module.secrets-manager.session_db_secret_arn
}

output "rabbitmq_secret_arn" {
  description = "RabbitMQ secret ARN"
  value       = module.secrets-manager.rabbitmq_secret_arn
}

# EBS CSI Driver Outputs
output "ebs_csi_iam_role_arn" {
  description = "EBS CSI driver IAM role ARN"
  value       = module.irsa.ebs_csi_driver_role_arn
}

# kubectl Configuration Command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-2 --profile DevOpsTeam-014498640042"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment    = var.environment
    region         = "us-east-2"
    cluster_name   = module.eks.cluster_name
    cluster_version = var.kubernetes_version
    node_count     = var.node_desired_size
    vpc_cidr       = var.vpc_cidr
  }
}

output "ebs_csi_driver_role_arn" {
  description = "IAM role ARN for EBS CSI Driver"
  value       = module.ebs-csi-driver.iam_role_arn
}

output "ebs_csi_addon_id" {
  description = "EBS CSI Driver Addon ID"
  value       = module.ebs-csi-driver.addon_id
}
