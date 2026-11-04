locals {
  account_id   = "492613460415"
  region       = "eu-central-1"
  project      = "eks-lab"
  cluster_name = "eks-lab"
  state_bucket = "${local.account_id}-${local.region}-eks-lab-tfstate"

  common_tags = {
    Project     = "eks-lab"
    Environment = "lab"
    ManagedBy   = "terragrunt"
    Owner       = "abevz"
    Repo        = "eks-irsa-lab"
  }

  local_overrides = fileexists("${get_parent_terragrunt_dir()}/local.hcl") ? read_terragrunt_config("${get_parent_terragrunt_dir()}/local.hcl").locals : {}
}

remote_state {
  backend      = "s3"
  disable_init = true
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = local.state_bucket
    key          = "${local.project}/${replace(path_relative_to_include(), "lab/.terragrunt-stack/", "lab/")}/tofu.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-HCL
    variable "default_tags" {
      description = "Tags applied to every resource this unit creates."
      type        = map(string)
      default     = {}
    }

    provider "aws" {
      region              = "${local.region}"
      allowed_account_ids = ["${local.account_id}"]
      default_tags { tags = var.default_tags }
    }
  HCL
}

errors {
  retry "aws_transient" {
    retryable_errors   = ["(?s).*ThrottlingException.*", "(?s).*RequestLimitExceeded.*", "(?s).*connection reset by peer.*", "(?s).*TLS handshake timeout.*"]
    max_attempts       = 3
    sleep_interval_sec = 8
  }
}

inputs = {
  default_tags = local.common_tags
}
