region = "ap-south-1"
tags = {
  Environment = "lab"
  project     = "intro-to-vpc"  # Required for resource naming
  Lab         = "01-vpc-subnet"
}

vpc_cidr = "10.0.0.0/16"
vpc_name = "main"
num_subnets = "2"