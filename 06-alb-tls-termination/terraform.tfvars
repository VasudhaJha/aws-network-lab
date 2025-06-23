alb_ingress_ports = [ "80", "443" ]
vpc_cidr = "10.0.0.0/16"
vpc_name = "alb-tls-termination-lab-vpc"
num_private_subnets = 2
num_public_subnets = 2
tags = {
  Environment = "lab"
  project     = "alb-tls-termination"  # Required for resource naming
  Lab         = "06-alb-tls-termination"
}
region = "ap-south-1"
