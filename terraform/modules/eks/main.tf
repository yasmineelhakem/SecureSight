# Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
# https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
# https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType

resource "aws_eks_cluster" "main" {
  name     = "eks-${var.environment}"
  version  = var.kubernetes_version
  role_arn = var.eks_cluster_role_arn  # from iam module

  # eks control plane connection to vpc
  vpc_config {
    subnet_ids = concat(           
      var.private_subnet_ids, # nodes live in private subnet
      var.public_subnet_ids   # LB discovery needs public subnet
    )
  }

  tags = merge(var.tags, {
    Name = "eks-${var.environment}"
  })
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "node-group-${var.environment}"
  node_role_arn   = var.eks_node_role_arn   # from iam module
  subnet_ids      = var.private_subnet_ids  # nodes always in private

  scaling_config {
    desired_size = var.node_desired_size   
    min_size     = var.node_min_size       
    max_size     = var.node_max_size       
  }

  # EC2 instance configuration
  instance_types = [var.node_instance_type]  # the default one is t3.medium
  ami_type       = "AL2_x86_64"             
  disk_size      = 20   # GB per node (cost efficient)

  update_config {
    max_unavailable = 1   
  }

  tags = merge(var.tags, {
    Name = "node-group-${var.environment}"
  })

  # Node group must wait for IAM role policies to be attached
  # otherwise nodes start without proper permissions
  depends_on = [var.eks_node_role_arn]
}


data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "oidc-${var.environment}"
  })
}