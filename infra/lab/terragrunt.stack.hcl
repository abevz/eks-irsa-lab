# infra/lab/terragrunt.stack.hcl
locals {
  units = "${get_repo_root()}/infra/units"
}

unit "network" {
  source = "${local.units}/network"
  path   = "network"
}

unit "cluster" {
  source = "${local.units}/cluster"
  path   = "cluster"
}

unit "identity" {
  source = "${local.units}/identity"
  path   = "identity"
}
