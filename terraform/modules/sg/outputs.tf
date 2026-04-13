output "lb_security_group_id" {
  description = "The ID of the Load Balancer security group"
  value       = aws_security_group.lb.id
}

output "eks_nodes_security_group_id" {
  description = "The ID of the EKS Nodes security group"
  value       = aws_security_group.eks_nodes.id
}