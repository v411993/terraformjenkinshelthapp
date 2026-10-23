# Find Own machine public ip address

 data "http" "my_ip" {
   url = "https://api.ipify.org"
 }


# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cidr_block           = "10.0.0.0/16"
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  cluster_name         = var.cluster_name
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  # Public node group
  public_node_group = {
    instance_types = ["t3.medium"]
    min_size       = var.public_node_group_min_size
    max_size       = var.public_node_group_max_size
    desired_size   = var.public_node_group_desired_size
    subnet_ids     = module.vpc.public_subnet_ids
  }
  
   cluster_endpoint_private_access = true
   cluster_endpoint_public_access  = true
   cluster_endpoint_public_access_cidrs = [
     "${chomp(data.http.my_ip.response_body)}/32"
   ]
  # Private node group
  private_node_group = {
    instance_types = ["t3.medium"]
    min_size       = var.private_node_group_min_size
    max_size       = var.private_node_group_max_size
    desired_size   = var.private_node_group_desired_size
    subnet_ids     = module.vpc.private_subnet_ids
  }
}

# ECR Module (only if repositories are specified)
module "ecr" {
  source = "./modules/ecr"

  repository_names = var.ecr_repository_names

  count = length(var.ecr_repository_names) > 0 ? 1 : 0
}
