vpc_cidr = "10.0.0.0/16"
vpc_name = "route53-lab-vpc"
num_private_subnets = 2
num_public_subnets = 2
tags = {
  Environment = "lab"
  project     = "route53-dns-integration"  # Required for resource naming
  Lab         = "05-route53-dns-integration"
}
region = "ap-south-1"