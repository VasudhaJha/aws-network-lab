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
  
  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

# --------------------------
# Internet Gateway
# --------------------------

/*
Creates an Internet Gateway and attaches it to the VPC.
This is required for outbound internet access via NAT Gateway or public instances.
*/
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "${var.tags["project"]}-igw"
  })
}

# --------------------------
# Fetch AZs Dynamically
# --------------------------

/*
Fetches the list of available Availability Zones in the current region.
Used to evenly distribute subnets across AZs.
*/
data "aws_availability_zones" "available" {}

# --------------------------
# Subnet Configuration
# --------------------------

/*
Defines CIDR blocks and AZ mappings for both private and public subnets.

- `private_subnet_config`: Creates `var.num_subnets` private subnets across multiple AZs.
- `public_subnet_config`: Creates one public subnet in the first AZ, used to host the NAT Gateway.

The public subnet CIDR is carved after the private ones by passing `var.num_subnets` as the index to `cidrsubnet()`. This avoids overlap with private subnet ranges.
*/

locals {
  private_subnet_config = {
    for i in range(var.num_private_subnets) :
    "private-subnet-${i}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      az   = data.aws_availability_zones.available.names[i]
    }
  }

  public_subnet_config = {
    for i in range(var.num_public_subnets) :
    "public-subnet-${i}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + var.num_private_subnets)
      az   = data.aws_availability_zones.available.names[i]
    }
  }
}

# --------------------------
# Public Subnet Configuration
# --------------------------

/*
Creates one public subnet in the first AZ.
This subnet will host the NAT Gateway and is associated with a route table that points to the Internet Gateway.
*/

resource "aws_subnet" "public" {
  for_each = local.public_subnet_config

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.key
  })
}

/*
Creates a route table for the public subnet with a default route to the Internet Gateway.
This allows outbound internet access for anything inside the public subnet (e.g. NAT Gateway).
*/
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-public-rt"
  })
}

/*
Associates the public subnet with the public route table.
This is what actually makes the subnet "public" — by giving it a route to the Internet Gateway.
*/
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --------------------------
# Private Subnet Configuration
# --------------------------


/*
Creates multiple private subnets in different AZs using the config above.
These subnets are considered "private" because their route table does not connect to an Internet Gateway directly.
*/
resource "aws_subnet" "private" {
  for_each = local.private_subnet_config

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr

  tags = merge(var.tags, {
    Name = each.key
  })
}

# --------------------------
# NAT Gateway + Elastic IP
# --------------------------

/*
Creates an Elastic IP to attach to the NAT Gateway.
This provides a static, publicly routable IPv4 address.
*/
resource "aws_eip" "eip" {
    domain = "vpc" # Indicates if this EIP is for use in VPC.
}

/*
Creates the NAT Gateway in the first public subnet.
Associates the Elastic IP to allow outbound access from private subnets.

NOTE:
NAT Gateways must be created in a **public subnet** for outbound internet access.
*/
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public["public-subnet-0"].id

  tags = merge({
    Name = "${var.tags["project"]}-nat"
  })

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# --------------------------
# Private Route Table
# --------------------------

/*
Creates a route table with a default route pointing to the NAT Gateway.
This allows private subnets to send outbound traffic through the NAT Gateway.
*/
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = merge({
    Name = "${var.tags["project"]}-private-rt"
  })
}

# --------------------------
# Route Table Association
# --------------------------

/*
Associates each private subnet with the private route table.
This enables NAT-based outbound internet access from private instances.
*/
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}