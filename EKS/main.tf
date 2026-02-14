module "vpc" {
  source = "./modules/vpc"

  project_name = "devsecops"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones = ["ap-south-1a", "ap-south-1b"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "devsecops-eks-cluster"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  node_instance_type = "t3.large"
  desired_size = 1
  min_size = 1
  max_size = 2
}