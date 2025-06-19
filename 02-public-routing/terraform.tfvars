region = "ap-south-1"
tags = {
  Environment = "lab"
  project     = "public-routing"  # Required for resource naming
  Lab         = "02-public-routing"
}

vpc_cidr                = "10.0.0.0/16"
vpc_name                = "main"
num_subnets             = "2"
igw_name                = "aws-network-lab-igw"
public_route_table_name = "aws-network-lab-public-rt"