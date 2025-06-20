# ------------------------------------
# VPC Module Invocation
# ------------------------------------

/*
Invokes the VPC module to provision:
- A custom VPC
- Public and private subnets
- Internet Gateway and NAT Gateway
- Route tables

The outputs from this module (like subnet IDs and VPC ID) are used in the rest of the infrastructure.
*/

module "vpc" {
    source = "../modules/vpc"
    vpc_cidr = var.vpc_cidr
    vpc_name = var.vpc_name
    num_private_subnets = var.num_private_subnets
    num_public_subnets = var.num_public_subnets
    tags = var.tags
}

# ------------------------------------
# ALB Configuration
# ------------------------------------

/*
Creates an external Application Load Balancer.
It listens on port 80 (HTTP) and is associated with public subnets to be internet-accessible.
*/

resource "aws_lb" "alb" {
  name = "${var.tags["project"]}-alb"
  internal = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnet_ids # AWS requires you to specify at least two subnets in two distinct AZs for high availability.
  security_groups = [aws_security_group.alb_sg.id]
}

# ------------------------------------
# ALB Security Group
# ------------------------------------

/*
Creates a security group that:
- Allows inbound HTTP (port 80) from anywhere (0.0.0.0/0)
- Allows all outbound traffic
*/

resource "aws_security_group" "alb_sg" {
  name = "allow_http"
  description = "allow http requests to reach the ALB on port 80"
  vpc_id = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "alb_allow_http"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ------------------------------------
# Target Groups (Green and Blue)
# ------------------------------------

/*
Creates target groups for each app version (green and blue).
Each target group:
- Uses HTTP on port 80
- Performs health checks on its respective path (/green or /blue)
*/

resource "aws_lb_target_group" "green" {
  name = "green-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path = var.green_app_path
    matcher = "200-399"
    interval = var.health_check_interval
    timeout = var.health_check_timeout
    healthy_threshold = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = "green-tg"
  })
}

resource "aws_lb_target_group" "blue" {
  name = "blue-tg"
  port = 80 # When I forward traffic to this target group, send it to targets on port X.
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path = var.blue_app_path
    matcher = "200-399"
    interval = var.health_check_interval
    timeout = var.health_check_timeout
    healthy_threshold = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = "blue-tg"
  })
}

# ------------------------------------
# Target Group Attachments
# ------------------------------------

/*
Registers EC2 instances as targets in the respective target groups.
Each EC2 instance listens on port 80.
*/

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.green.arn
  target_id = aws_instance.green.id
  port = 80
}


resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.blue.arn
  target_id = aws_instance.blue.id
  port = 80
}

# ------------------------------------
# ALB Listener & Rules
# ------------------------------------

/*
Creates an HTTP listener on port 80 for the ALB.
Requests not matching any rule return a 400 fixed response.
*/

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "400 Bad Request"
      status_code  = "400"
    }
  }
}

resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.http.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = [var.green_app_path, "${var.green_app_path}/"]
    }
  }
}

resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.http.arn
  priority = 2

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = [var.blue_app_path, "${var.blue_app_path}/"]
    }
  }
}

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
  description = "allow inbound traffic from alb sg"
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

resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = file("${path.module}/${var.key_name}.pub")
}

/*
Creates the Blue app EC2 instance:
- Hosted in private_subnet_0
- Serves content from /var/www/html/blue
- Defines NGINX location block for /blue
*/

resource "aws_instance" "blue" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name
  
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
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnet_ids[1]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name
  
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

# ------------------------------------
# Route53 Configuration
# ------------------------------------

/*
Looks up the existing public hosted zone for your domain.
Since I directly registered the domain directly with Route 53, AWS automatically created this hosted zone.
This data source allows Terraform to reference the hosted zone dynamically, without hardcoding the zone ID.
*/
data "aws_route53_zone" "my_zone" {
    name = var.domain_name
    private_zone = false
}

/*
Creates an Alias A record for the root domain (apex domain).
- This maps aws-network-lab.com directly to the ALB.
- Uses Alias (instead of CNAME) because:
  - Alias supports apex domains
  - Alias is AWS-native and integrates directly with AWS-managed resources like ALB
  - Faster DNS resolution with no extra lookup
- Alias requires:
  - ALB DNS name
  - ALB zone ID (provided by aws_lb resource)
*/

resource "aws_route53_record" "root_alias" {
  zone_id = data.aws_route53_zone.my_zone.id
  name = ""
  type = "A"

  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

/*
Creates an Alias A record for www subdomain - CONDITIONALLY CREATED
- Only created when var.create_www_record is true
- Technically this could be a CNAME (since it's a subdomain),
  but Alias A is better for AWS-native resources because:
  - Faster resolution (no additional lookup)
  - Fully integrated with ALB
- Allows users to access www.aws-network-lab.com (optional, but common)
*/
resource "aws_route53_record" "www_alias" {
  count = var.create_www_record ? 1 : 0
  zone_id = data.aws_route53_zone.my_zone.id
  name = "www"
  type = "A"

  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}



