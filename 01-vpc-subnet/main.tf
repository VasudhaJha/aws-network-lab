/*
Key arguments when defining a VPC
1. cidr_block -> Defines the IP range
2. enable_dns_support -> Enables private DNS resolution within the VPC. (defaults to true)
3. enable_dns_hostnames ->	Needed if instances should get public DNS names. (defaults to false)
4. instance_tenancy	-> Leave as "default" unless you're using Dedicated Instances (costly)
5. tags -> 	Helps with organization and filtering in the AWS console
*/

# ---- VPC Block ----
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

# ---- Get list of AZs ----
data "aws_availability_zones" "available" {
  state = "available"
}

# ---- Local subnet configuration ----
locals {
  actual_num_subnets = min(var.num_subnets, length(data.aws_availability_zones.available.names))
  subnet_config = {
    for i in range(var.num_subnets):
    "subnet-${data.aws_availability_zones.available.names[i]}" => {
        cidr = cidrsubnet(var.vpc_cidr, var.subnet_newbits, i)
        az = data.aws_availability_zones.available.names[i]
    } 
  }
}

/*
Key arguments when defining a Subnet
1. vpc_id -> Tells AWS which VPC the subnet belongs to
2. cidr_block -> Defines the IP address range for the subnet (must be a subset of VPC)
3. availability_zone -> Spreads subnets across different AZs for high availability
4. map_public_ip_on_launch -> Automatically assigns public IPs to instances launched here
5. tags -> Helps identify and organize the subnets
*/

# ---- Create subnets ----
resource "aws_subnet" "subnets" {
  for_each = local.subnet_config

  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = each.key
  })
}