provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.17.1" # Use the latest stable version

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "karpenter" {
  depends_on = [ helm_release.cert_manager ]

  name       = "karpenter"
  namespace  = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"

  create_namespace = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = var.cluster_endpoint  # Pass the cluster endpoint
  }  
  
  set {
    name  = "webhook.generateTLS"
    value = "true"  # Enables automatic webhook TLS cert creation
  }

  set {
    name  = "webhook.certManager.enabled"
    value = "true"  # Ensures Cert Manager is used for certificates
  }
}