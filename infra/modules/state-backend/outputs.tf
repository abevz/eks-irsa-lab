# infra/modules/state-backend/outputs.tf
output "bucket_name" {
  value       = aws_s3_bucket.state.id
  description = "Name of the S3 bucket that stores remote state"
}

output "bucket_arn" {
  value       = aws_s3_bucket.state.arn
  description = "ARN of the state bucket"
}
