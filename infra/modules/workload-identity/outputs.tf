# infra/modules/workload-identity/outputs.tf
output "lb_controller_role_arn" {
  value       = module.lb_controller_irsa.iam_role_arn
  description = "IRSA role consumed by the AWS Load Balancer Controller chart"
}
output "external_dns_role_arn" {
  value       = module.external_dns_irsa.iam_role_arn
  description = "IRSA role consumed by the external-dns chart"
}
