# infra/modules/network/main.tf — thin wrapper over the community VPC module: pins the subnet tags the ALB controller needs
data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:slice(names, 0, 2) takes the first two sorted AZs; a newly added AZ sorts after them
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = var.name
  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = [for i, _ in local.azs : cidrsubnet("10.0.0.0/16", 8, i + 1)]
  private_subnets = [for i, _ in local.azs : cidrsubnet("10.0.0.0/16", 8, i + 11)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true

  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}


