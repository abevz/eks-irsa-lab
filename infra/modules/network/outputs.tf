# infra/modules/network/outputs.tf
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for the cluster and the Load Balancer Controller"
}
output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "Subnets for control plane ENIs and worker nodes"
}
