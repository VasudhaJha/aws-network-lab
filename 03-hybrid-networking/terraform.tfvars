region = "ap-south-1"
tags = {
  Environment = "lab"
  project     = "private-networking"  # Required for resource naming
  Lab         = "03-private-routing"
}

vpc_cidr                = "10.0.0.0/16"
vpc_name                = "main"
num_subnets             = "2"