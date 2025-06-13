# --------------------------
# VPC Configuration
# --------------------------

/*
Creates a custom VPC with DNS support and DNS hostnames enabled.
This allows EC2 instances to resolve domain names and get public DNS names when launched with public IPs.
*/

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr # Defines the IP range
  enable_dns_support = true # Enables private DNS resolution within the VPC. (defaults to true)
  enable_dns_hostnames = true # Needed if instances should get public DNS names. (defaults to false)
  instance_tenancy = "default" # Leave as "default" unless you're using Dedicated Instances (costly)

  tags = merge(var.tags, {
    Name = var.vpc_name
  }) # Helps with organization and filtering in the AWS console
}

# --------------------------
# Fetch AZs Dynamically
# --------------------------

/*
Fetches the list of available Availability Zones in the current region.
Used to evenly distribute subnets across AZs.
*/
data "aws_availability_zones" "available" {
  state = "available"
}

# --------------------------
# Subnet Configuration
# --------------------------

/*
Generates subnet CIDRs and corresponding AZs dynamically.
Uses `cidrsubnet()` to carve blocks from the VPC CIDR.
*/
locals {
  actual_num_subnets = min(var.num_subnets, length(data.aws_availability_zones.available.names))
  subnet_config = {
    for i in range(local.actual_num_subnets):
    "subnet-${data.aws_availability_zones.available.names[i]}" => {
        cidr = cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)
        az = data.aws_availability_zones.available.names[i]
    } 
  }
}

/*
Creates multiple subnets in different AZs using the map above.
*/
resource "aws_subnet" "subnets" {
  for_each = local.subnet_config

  vpc_id = aws_vpc.main.id # Tells AWS which VPC the subnet belongs to
  cidr_block = each.value.cidr # Defines the IP address range for the subnet (must be a subset of VPC)
  availability_zone = each.value.az # Spreads subnets across different AZs for high availability

  tags = merge(var.tags, {
    Name = each.key
  })
}