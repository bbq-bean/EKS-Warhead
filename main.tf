module "network" {
  source = "./modules/network"
}

module "kubernetes" {
  source = "./modules/EKS"
  private_subnet_1_id = module.network.private_subnet_1_id
  private_subnet_2_id = module.network.private_subnet_2_id
  vpc_id = module.network.vpc_id
  
}

module "plugins_karpenter" {
  source = "./modules/EKS-plugins/karpenter"
  cluster_name = module.kubernetes.cluster_name
  cluster_endpoint = module.kubernetes.cluster_endpoint
  cluster_certificate_authority_data = module.kubernetes.cluster_certificate_authority_data
}