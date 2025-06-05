# --------------------------
# VPC Configuration
# --------------------------

/*
Creates a custom VPC with DNS support and DNS hostnames enabled.
This allows EC2 instances to resolve domain names and get public DNS names when launched with public IPs.
*/

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
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
  public_subnet_config = {
    for i in range(var.num_subnets):
    "public-subnet-${i}" => {
        cidr = cidrsubnet(var.vpc_cidr, 8, i)
        az = data.aws_availability_zones.available.names[i]
    }
  }
}

/*
Creates multiple subnets in different AZs using the map above.
*/
resource "aws_subnet" "public" {
  for_each = local.public_subnet_config

  vpc_id = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.key
  })
}


# --------------------------
# Internet Gateway
# --------------------------

/*
Creates an Internet Gateway and attaches it to the VPC.
Needed for public internet access.
*/
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = var.igw_name
  })
}

# --------------------------
# Public Route Table
# --------------------------

/*
Creates a route table with a default route (0.0.0.0/0) pointing to the IGW.
This route allows subnets associated with this table to send traffic to the internet.
*/
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = var.public_route_table_name
  })
}

# --------------------------
# Route Table Association
# --------------------------

/*
Associates each public subnet with the public route table.
This is what actually makes the subnet "public" — it gives it a route to the internet.
*/
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}