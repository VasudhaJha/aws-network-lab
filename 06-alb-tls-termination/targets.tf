# ------------------------------------
# EC2 Instance Security Group
# ------------------------------------

/*
Security group for EC2 instances that:
- Allows inbound HTTP from the ALB SG
- Allows all outbound traffic
*/

resource "aws_security_group" "web_sg" {
  name = "allow_alb_inbound"
  description = "Allow inbound traffic from ALB security group"
  vpc_id = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "allow_alb_inbound"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_inbound" {
  security_group_id = aws_security_group.web_sg.id
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_out" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1" # allow all protocols, no restrictions
}

# ------------------------------------
# EC2 Instances (Blue and Green)
# ------------------------------------

/*
Fetches the latest Ubuntu 20.04 AMI (HVM, SSD-backed).
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

/*
Creates the Blue app EC2 instance:
- Hosted in private_subnet_0
- Serves content from /var/www/html/blue
- Defines NGINX location block for /blue
*/
resource "aws_instance" "blue" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y

              mkdir -p /var/www/html/blue
              echo "<h1>Welcome to the Blue App</h1>" > /var/www/html/blue/index.html

              echo 'server {
                  listen 80;
                  root /var/www/html;
                  location /blue {
                      try_files $uri $uri/ $uri/index.html =404;
                  }
              }' > /etc/nginx/sites-available/default

              systemctl restart nginx
  EOF

  tags = merge(var.tags, {
    Name = "blue-server"
  })
}

/*
Creates the Green app EC2 instance:
- Hosted in private_subnet_1
- Serves content from /var/www/html/green
- Defines NGINX location block for /green
*/
resource "aws_instance" "green" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y

              mkdir -p /var/www/html/green
              echo "<h1>Welcome to the Green App</h1>" > /var/www/html/green/index.html

              echo 'server {
                  listen 80;
                  root /var/www/html;
                  location /green {
                      try_files $uri $uri/ $uri/index.html =404;
                  }
              }' > /etc/nginx/sites-available/default

              systemctl restart nginx
  EOF
  tags = merge(var.tags, {
    Name = "green-server"
  })
}