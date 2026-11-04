# infra/modules/edge/output.tf
output "certificate_arn" {
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
  description = "Validated wildcard certificate for the ALB"
}

output "zone_id" {
  value       = data.aws_route53_zone.main.zone_id
  description = "Existing hosted zone; read, never created"
}
