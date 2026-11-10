# infra/modules/eks-platform/main.tf

# Public API endpoint is intentional: kubectl from the laptop. Access is limited by
# public_access_cidrs (owner IP from gitignored local.hcl; 0.0.0.0/0 is rejected by validation).
# Node egress to 0.0.0.0/0: nodes pull images and call AWS APIs through the NAT gateway.
#trivy:ignore:AVD-AWS-0040
#trivy:ignore:AVD-AWS-0104
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                               = var.vpc_id
  subnet_ids                           = var.private_subnet_ids
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  cluster_endpoint_public_access           = true
  authentication_mode                      = "API"
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium"]
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      subnet_ids     = var.private_subnet_ids
    }
  }

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }
}

