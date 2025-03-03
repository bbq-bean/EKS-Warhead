module "network" {
  source = "./modules/network"
}

module "kubernetes" {
  source = "./modules/EKS"
}