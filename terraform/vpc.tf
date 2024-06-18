# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "= 5.8.1"

  name = local.name
  cidr = local.vpc.cidr
  azs  = slice(data.aws_availability_zones.region.names, 0, 2)
  public_subnets = [
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 0),
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 1),
  ]
  private_subnets = [
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 10),
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 11),
  ]

  map_public_ip_on_launch      = false
  public_subnet_ipv6_prefixes  = [0, 1]
  private_subnet_ipv6_prefixes = [10, 11]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false
}



