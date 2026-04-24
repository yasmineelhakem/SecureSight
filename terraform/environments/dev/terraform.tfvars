environment  = "dev"

tags = {
  Owner = "yasmine"
}

vpc_cidr = "10.0.0.0/16"

availability_zones   = ["us-east-2a", "us-east-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

kubernetes_version = "1.31"
node_instance_type = "t3.medium"
node_desired_size  = 2
node_min_size      = 1
node_max_size      = 4

certificate_arn   = null

# EBS CSI driver
ebs_csi_addon_version = null  