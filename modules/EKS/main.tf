resource "aws_security_group" "eks_sg" {
  name        = "eks-security-group"
  description = "Security group allowing all egress and intra-group communication"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic (egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows traffic to any destination
  }

  # Allow all inbound traffic from instances within the same security group
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    Name = "eks-security-group"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.34"

  cluster_name    = "eks-warhead-staging"
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = false

  access_entries = {
      bastion-admin = {
        principal_arn = "arn:aws:iam::105798279251:role/bastion-with-admin"

        policy_associations = {
          this = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
  }
  # dont configure KMS cluster encryption
  kms_key_enable_default_policy = false
  cluster_encryption_config = {}

  bootstrap_self_managed_addons = true

    # Install managed add-ons and inherit IAM permissions from node role
  cluster_addons = {
    vpc-cni = {
      resolve_conflicts      = "OVERWRITE"
      service_account_role_arn = null  # Inherit from node IAM role
    }
    kube-proxy = {
      resolve_conflicts      = "OVERWRITE"
      service_account_role_arn = null  # Inherit from node IAM role
    }
    coredns = {
      resolve_conflicts      = "OVERWRITE"
      service_account_role_arn = null  # Inherit from node IAM role
    }
    eks-pod-identity-agent = {
      resolve_conflicts      = "OVERWRITE"
      service_account_role_arn = null  # Inherit from node IAM role
    }
  }

  eks_managed_node_groups = {
    utility-ng = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]

  create_cluster_security_group = false
  create_node_security_group = false

  cluster_security_group_id = aws_security_group.eks_sg.id

  node_security_group_id                       = aws_security_group.eks_sg.id
  node_security_group_enable_recommended_rules = false

  tags = {
    Environment = "staging"
  }
}

# add extra required policy for karpenter
resource "aws_iam_role_policy_attachment" "karpenter_price_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSPriceListServiceFullAccess"
  role       = module.eks.eks_managed_node_groups["utility-ng"].iam_role_name
}

resource "aws_iam_role_policy_attachment" "karpenter_spot_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = module.eks.eks_managed_node_groups["utility-ng"].iam_role_name
}


output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

