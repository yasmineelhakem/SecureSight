output "external_secrets_role_arn" {
  description = "ARN of External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "external_secrets_role_name" {
  description = "Name of External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.name
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_driver_role_name" {
  description = "Name of EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.name
}
