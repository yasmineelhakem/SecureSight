module "vpc" {
  source      = "../../modules/vpc"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  tags        = var.tags
}

module "subnets" {
  source               = "../../modules/subnets"
  vpc_id               = module.vpc.vpc_id
  environment          = var.environment
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}

module "routes" {
  source              = "../../modules/routes"
  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  nat_gateway_id      = module.subnets.nat_gateway_id
  public_subnet_ids   = module.subnets.public_subnet_ids
  private_subnet_ids  = module.subnets.private_subnet_ids
  environment         = var.environment
  tags                = var.tags
}

module "sg" {
  source = "../../modules/sg"
  vpc_id = module.vpc.vpc_id
  environment = var.environment
  tags = var.tags
}

module "iam" {
  source      = "../../modules/iam"
  environment = var.environment
  tags        = var.tags
}

module "eks" {
  source                  = "../../modules/eks"
  environment             = var.environment
  kubernetes_version      = var.kubernetes_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.subnets.private_subnet_ids
  public_subnet_ids       = module.subnets.public_subnet_ids
  eks_cluster_role_arn    = module.iam.eks_cluster_role_arn
  eks_node_role_arn       = module.iam.eks_node_role_arn
  eks_nodes_sg_id         = module.sg.eks_nodes_security_group_id
  node_instance_type      = var.node_instance_type
  node_desired_size       = var.node_desired_size
  node_min_size           = var.node_min_size
  node_max_size           = var.node_max_size
  tags                    = var.tags
}

module "lb" {
  source               = "../../modules/lb"
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.subnets.public_subnet_ids
  lb_security_group_id = module.sg.lb_security_group_id
  certificate_arn      = var.certificate_arn
  tags                 = var.tags
}

module "secret_manager" {
  source         = "../../modules/secret-manager"
  environment    = var.environment
  
  mongodb_username      = var.mongodb_username
  mongodb_password      = var.mongodb_password
  mongodb_uri           = var.mongodb_uri
  
  mariadb_root_password = var.mariadb_root_password
  mariadb_user          = var.mariadb_user
  mariadb_password      = var.mariadb_password
  mariadb_database      = var.mariadb_database
  
  redis_password        = var.redis_password
  
  rabbitmq_username     = var.rabbitmq_username
  rabbitmq_password     = var.rabbitmq_password
  
  tags                  = var.tags
}

module "irsa" {
  source            = "../../modules/irsa"
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = replace(module.eks.oidc_provider_url, "https://", "")
  tags              = var.tags

  depends_on = [module.eks]
}