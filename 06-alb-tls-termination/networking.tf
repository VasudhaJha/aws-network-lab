# ------------------------------------
# VPC Module Invocation
# ------------------------------------

/*
Invokes the VPC module to provision:
- A custom VPC
- Public and private subnets
- Internet Gateway and NAT Gateway
- Route tables

The outputs from this module (like subnet IDs and VPC ID) are used in the rest of the infrastructure.
*/
module "vpc" {
  source = "../modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  num_private_subnets = var.num_private_subnets
  num_public_subnets = var.num_public_subnets
  tags = var.tags
}

