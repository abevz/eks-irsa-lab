# infra/modules/registry/outputs.tf
output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "Push target for the lab image"
}
