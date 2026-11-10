# infra/modules/workload-identity/variables.tf
variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN exported by the cluster unit"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name exported by the cluster unit"
}

variable "zone_id" {
  type        = string
  description = "Hosted zone that external-dns may change (from the edge unit)"
}
