
module "eks" {
 source  = "terraform-aws-modules/eks/aws"
 version = "~> 20.31"

 cluster_name    = "example"
 cluster_version = "1.31"

 # Optional
 cluster_endpoint_public_access = true

 # Optional: Adds the current caller identity as an administrator via cluster access entry
 enable_cluster_creator_admin_permissions = true

 eks_managed_node_groups = {
   example = {
     instance_types = ["t3.medium"]
     min_size       = 2
     max_size       = 2
     desired_size   = 2
   }
 }

 vpc_id     = var.vpc_id
 subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]

 tags = {
   Environment = "dev"
   Terraform   = "true"
 }
}