# infra/persistent/edge/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules//edge"
}

inputs = {
  domain = "bevz.click"
}
