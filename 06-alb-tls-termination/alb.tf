# ------------------------------------
# ALB Configuration
# ------------------------------------

/*
Creates an external Application Load Balancer.
It listens on port 80 (HTTP) and port 443 (HTTPS) and is associated with public subnets to be internet-accessible.
*/

resource "aws_lb" "alb" {
  name = "${var.tags["project"]}-alb"
  internal = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnet_ids
  security_groups = [aws_security_group.alb_sg.id]
}

# ------------------------------------
# ALB Security Group
# ------------------------------------

/*
Creates a security group that:
- Allows inbound HTTP (port 80) and HTTPS (port 443) from anywhere (0.0.0.0/0)
- Allows all outbound traffic
*/

resource "aws_security_group" "alb_sg" {
  name="allow_http_https"
  description = "allow inbound HTTP and HTTP traffic and allow all outbound"
  vpc_id = module.vpc.vpc_id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  for_each = toset(var.alb_ingress_ports)

  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = each.value
  ip_protocol       = "tcp"
  to_port           = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4 = "0.0.0.0/0" #destination IP range for the traffic allowed in this rule.
    ip_protocol = -1
}

# ------------------------------------
# Target Groups (Green and Blue)
# ------------------------------------

/*
Creates target groups for each app version (green and blue).

When a client connects on HTTPS (port 443), ALB:
- Handles the TLS handshake
- Decrypts the traffic
- Forwards plain HTTP traffic internally to the target group (on port 80).

Each target group:
- Uses HTTP on port 80
- Performs health checks on its respective path (/green or /blue)

*/

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
Creates an HTTPS listener on port 443 for the ALB.
Requests not matching any rule return a 400 fixed response.
*/

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.tls_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "400 Bad Request"
      status_code  = "400"
    }
  }
}

/*
Listener rules that forward based on path patterns.
- Requests to `/green*` go to green target group.
- Requests to `/blue*` go to blue target group.
*/

resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/green", "/green*"]
    }
  }
}

resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/blue", "/blue*"]
    }
  }
}


/*
Creates an HTTP listener on port 80 for the ALB.
It will redirect to port 443
*/

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}




