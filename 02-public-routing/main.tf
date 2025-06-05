# --------------------------
# VPC Configuration
# --------------------------

/*
Creates a custom VPC with DNS support and DNS hostnames enabled.
This allows EC2 instances to resolve domain names and get public DNS names when launched with public IPs.
*/
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

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
    for i in range(var.num_subnets) :
    "public-subnet-${i}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      az   = data.aws_availability_zones.available.names[i]
    }
  }
}

/*
Creates multiple subnets in different AZs using the map above.
*/
resource "aws_subnet" "public" {
  for_each = local.public_subnet_config

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
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

# --------------------------
# Security Group: Allow HTTP
# --------------------------

/*
Creates a security group scoped to the VPC. This SG allows:
- Inbound HTTP (port 80) traffic from within the VPC (can be modified to allow internet access)
- Outbound traffic to anywhere (0.0.0.0/0), which is the default for most EC2 use cases
We define rules separately using aws_vpc_security_group_ingress_rule and egress_rule,
as recommended by Terraform best practices.
*/
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "allow_http"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# --------------------------
# AMI Lookup for Ubuntu
# --------------------------

/*
Fetches the latest Ubuntu 20.04 LTS AMI (HVM, SSD-backed) in the current region.
This avoids hardcoding AMI IDs and makes the module region-agnostic.

We filter by:
- AMI name: ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*
- Virtualization type: hvm
- Owner: Canonical's AWS account (099720109477)
*/

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu)
}

# --------------------------
# EC2 Instance: Web Server
# --------------------------

/*
Launches an EC2 instance in one of the public subnets using the Ubuntu AMI.

- Automatically installs and starts NGINX using a user data script
- Associates a public IP to allow internet access
- Attaches the security group that allows HTTP (port 80) traffic
*/

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = values(aws_subnet.public)[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_http.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = merge(var.tags, {
    Name = "web-server"
  })
}


