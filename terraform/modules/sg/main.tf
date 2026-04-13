# Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "lb" {
  name        = "sg-lb-${var.environment}"
  description = "Security group for Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "sg-lb-${var.environment}"
  })
}

# inbound http from internet
resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.lb.id
  description       = "Allow HTTP from internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "lb-inbound-http"
  })
}

# inbound https from internet
resource "aws_vpc_security_group_ingress_rule" "lb_https" {
  security_group_id = aws_security_group.lb.id
  description       = "Allow HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "lb-inbound-https"
  })
}

# outbound all traffic allowed to anywhere 
resource "aws_vpc_security_group_egress_rule" "lb_outbound" {
  security_group_id = aws_security_group.lb.id
  description       = "Allow all outbound to EKS nodes"
  ip_protocol       = "-1"   # semantically equivalent to all ports
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "lb-outbound-all"
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "sg-eks-nodes-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "sg-eks-nodes-${var.environment}"
  })
}

# inbound from lb
resource "aws_vpc_security_group_ingress_rule" "nodes_from_lb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow all traffic from Load Balancer"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lb.id  

  tags = merge(var.tags, {
    Name = "nodes-inbound-from-lb"
  })
}

# inbound node to node communication (all ports)
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow node to node communication"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id  # ← self reference

  tags = merge(var.tags, {
    Name = "nodes-inbound-self"
  })
}

# inbound — control plane to nodes HTTPS port 443
resource "aws_vpc_security_group_ingress_rule" "nodes_from_cp_443" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow control plane to nodes HTTPS"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.cluster_security_group_id

  tags = merge(var.tags, {
    Name = "nodes-inbound-cp-443"
  })
}

# inbound — control plane to nodes kubelet port 10250 (for metrics, logs ...)
resource "aws_vpc_security_group_ingress_rule" "nodes_from_cp_kubelet" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow control plane to kubelet"
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.cluster_security_group_id

  tags = merge(var.tags, {
    Name = "nodes-inbound-cp-kubelet"
  })
}

# ountbound — allow all outbound from nodes 
resource "aws_vpc_security_group_egress_rule" "nodes_outbound" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow all outbound from nodes"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "nodes-outbound-all"
  })
}
