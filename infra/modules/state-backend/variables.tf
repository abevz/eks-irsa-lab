# infra/modules/state-backend/variables.tf
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for OpenTofu remote state"
}
