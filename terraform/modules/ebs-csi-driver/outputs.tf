output "addon_id" {
  description = "EBS CSI driver addon ID"
  value       = aws_eks_addon.ebs_csi_driver.id
}
