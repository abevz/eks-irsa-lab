# infra/persistent/registry/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules//registry"
}

inputs = {
  name = "democicd"
}
