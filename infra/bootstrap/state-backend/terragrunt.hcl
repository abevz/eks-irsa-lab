# infra/bootstrap/state-backend/terragrunt.hcl
# Creates the S3 bucket that holds every other unit's state.
# Account, region, bucket name, provider and tags come from root.hcl (single source of truth).
# Only remote_state is overridden: this unit's own state is LOCAL, because the bucket
# cannot hold the state of its own creation (chicken-and-egg).
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/infra/modules//state-backend"
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # Outside every worktree: the bootstrap state must survive worktree removal (decision 2026-11-09).
    path = "${get_env("LAB_HOME")}/.local/bootstrap-state/terraform.tfstate"
  }
}

inputs = {
  bucket_name = local.root.state_bucket
}
