# infra/modules/eks-platform/variables.tf
variable "vpc_id" {
  type        = string
  description = "VPC owned by the network unit"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for EKS control plane ENIs and worker nodes"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name; passed from root.hcl locals by the unit"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS minor version, e.g. 1.36; upgrade = change it in the unit (2.6)"
}


