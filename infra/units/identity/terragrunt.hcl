# infra/units/identity/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules//workload-identity"
}

dependency "cluster" {
  config_path = "../cluster"
  mock_outputs = {
    cluster_name      = "eks-lab"
    oidc_provider_arn = "mock-oidc-provider"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "edge" {
  config_path = "${get_repo_root()}/infra/persistent/edge"
  mock_outputs = {
    zone_id = "ZMOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  cluster_name      = dependency.cluster.outputs.cluster_name
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn
  zone_id           = dependency.edge.outputs.zone_id
}
