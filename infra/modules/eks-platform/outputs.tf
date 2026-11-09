# infra/modules/eks-platform/outputs.tf
output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name for add-ons and access entries"
}
output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "Exact EKS ARN used by destructive-operation guards"
}
output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN for IRSA roles"
}
