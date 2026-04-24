output "addon_id" {
  description = "EBS CSI driver addon ID"
  value       = aws_eks_addon.ebs_csi_driver.id
}

output "iam_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}