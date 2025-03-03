module "network" {
  source = "./modules/network"
}

module "kubernetes" {
  source = "./modules/EKS"
  private_subnet_1_id = module.network.private_subnet_1_id
  private_subnet_2_id = module.network.private_subnet_2_id
  vpc_id = module.network.vpc_id
  
}
