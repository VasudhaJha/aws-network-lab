module "vpc" {
  source = "../modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  num_public_subnets = var.num_public_subnets
  num_private_subnets = var.num_private_subnets
}

resource "aws_lb" "alb" {
  name               = "${var.tags["project"]}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnet_ids
  tags = var.tags
}

resource "aws_security_group" "alb_sg" {
  name        = "allow_http"
  description = "Allow http inbound traffic into alb and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "alb_allow_http"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_lb_target_group" "green" {
  name        = "green-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/green" # The HTTP path that the ALB uses to check if the target is healthy.
    matcher             = "200-399" # The expected status code range that is considered "healthy."
    interval            = 30 # How often (in seconds) the ALB performs health checks on the target.
    timeout             = 5 # How long (in seconds) the ALB waits for a response from the target.
    healthy_threshold   = 2 # The number of consecutive successful checks required to consider a target "healthy".
    unhealthy_threshold = 2 # The number of consecutive failed checks required to consider a target "unhealthy".
  }

  tags = merge(var.tags, {
    Name = "green-tg"
  })
}

resource "aws_lb_target_group" "blue" {
  name = "blue-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path = "/blue"
    matcher = "200-399"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "blue-tg"
  })
}


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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

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
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/green"]
    }
  }
}

resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/blue"]
    }
  }
}


//targets
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

resource "aws_instance" "blue" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y

              mkdir -p /var/www/html/blue
              echo "<h1>Welcome to the Blue App</h1>" > /var/www/html/blue/index.html

              echo 'server {
                  listen 80;

                  location /blue {
                      root /var/www/html;
                  }
              }' > /etc/nginx/sites-available/default

              systemctl restart nginx
  EOF

  tags = merge(var.tags, {
    Name = "blue-server"
  })
}

resource "aws_instance" "green" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnet_ids[1]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y

              mkdir -p /var/www/html/green
              echo "<h1>Welcome to the Green App</h1>" > /var/www/html/green/index.html

              echo 'server {
                  listen 80;

                  location /green {
                      root /var/www/html;
                  }
              }' > /etc/nginx/sites-available/default

              systemctl restart nginx
  EOF
  tags = merge(var.tags, {
    Name = "green-server"
  })
}