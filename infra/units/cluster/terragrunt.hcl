# infra/units/cluster/terragrunt.hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/infra/modules//eks-platform"

  extra_arguments "eks_patience" {
    commands  = ["apply", "destroy"]
    arguments = ["-lock-timeout=20m"]
  }
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_ids = dependency.network.outputs.private_subnet_ids
  cluster_name       = include.root.locals.cluster_name
  kubernetes_version = "1.36"
}
