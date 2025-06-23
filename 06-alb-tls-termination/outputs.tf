
# ------------------------------------
# VPC Outputs (from module)
# ------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs where ALB is deployed"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs where EC2 instances are deployed"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

# ------------------------------------
# Application Load Balancer Outputs
# ------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.alb.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_hosted_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer (for Route53)"
  value       = aws_lb.alb.zone_id
}

# ------------------------------------
# Target Group Outputs
# ------------------------------------

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "blue_target_group_name" {
  description = "Name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_name" {
  description = "Name of the green target group"
  value       = aws_lb_target_group.green.name
}

# ------------------------------------
# EC2 Instance Outputs
# ------------------------------------

output "blue_instance_id" {
  description = "Instance ID of the blue server"
  value       = aws_instance.blue.id
}

output "green_instance_id" {
  description = "Instance ID of the green server"
  value       = aws_instance.green.id
}

output "blue_instance_private_ip" {
  description = "Private IP address of the blue server"
  value       = aws_instance.blue.private_ip
}

output "green_instance_private_ip" {
  description = "Private IP address of the green server"
  value       = aws_instance.green.private_ip
}

output "blue_instance_az" {
  description = "Availability zone of the blue server"
  value       = aws_instance.blue.availability_zone
}

output "green_instance_az" {
  description = "Availability zone of the green server"
  value       = aws_instance.green.availability_zone
}

# ------------------------------------
# Security Group Outputs
# ------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "web_security_group_id" {
  description = "ID of the web servers security group"
  value       = aws_security_group.web_sg.id
}

# ------------------------------------
# Route53 Outputs
# ------------------------------------

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.my_zone.id
}

output "domain_name" {
  description = "Primary domain name"
  value       = var.domain_name
}

output "root_domain_record" {
  description = "Root domain A record"
  value       = aws_route53_record.root_alias.name
}

output "www_domain_record" {
  description = "WWW subdomain A record"
  value       = aws_route53_record.www_alias.name
}

# ------------------------------------
# Application URLs - HTTPS (Primary)
# ------------------------------------

output "blue_app_url_https" {
  description = "HTTPS URL to access blue app via custom domain"
  value       = "https://${var.domain_name}/blue"
}

output "green_app_url_https" {
  description = "HTTPS URL to access green app via custom domain"
  value       = "https://${var.domain_name}/green"
}

output "www_blue_app_url_https" {
  description = "HTTPS URL to access blue app via www subdomain"
  value       = "https://www.${var.domain_name}/blue"
}

output "www_green_app_url_https" {
  description = "HTTPS URL to access green app via www subdomain"
  value       = "https://www.${var.domain_name}/green"
}

# ------------------------------------
# Application URLs - HTTP (Redirects to HTTPS)
# ------------------------------------

output "blue_app_url_http_redirect" {
  description = "HTTP URL to access blue app (redirects to HTTPS)"
  value       = "http://${var.domain_name}/blue (redirects to HTTPS)"
}

output "green_app_url_http_redirect" {
  description = "HTTP URL to access green app (redirects to HTTPS)"
  value       = "http://${var.domain_name}/green (redirects to HTTPS)"
}

output "www_blue_app_url_http_redirect" {
  description = "HTTP URL to access blue app via www (redirects to HTTPS)"
  value       = "http://www.${var.domain_name}/blue (redirects to HTTPS)"
}

output "www_green_app_url_http_redirect" {
  description = "HTTP URL to access green app via www (redirects to HTTPS)"
  value       = "http://www.${var.domain_name}/green (redirects to HTTPS)"
}

# ------------------------------------
# ALB Direct Access URLs (for debugging)
# ------------------------------------

output "blue_app_url_alb_direct" {
  description = "Direct ALB URL to access blue app (useful for debugging)"
  value       = "https://${aws_lb.alb.dns_name}/blue"
}

output "green_app_url_alb_direct" {
  description = "Direct ALB URL to access green app (useful for debugging)"
  value       = "https://${aws_lb.alb.dns_name}/green"
}

# ------------------------------------
# Testing Commands
# ------------------------------------

output "test_commands" {
  description = "Commands to test the HTTPS setup, redirects, and SSL certificate"
  value = {
    # HTTPS Testing (Primary)
    blue_app_https     = "curl -L https://${var.domain_name}/blue"
    green_app_https    = "curl -L https://${var.domain_name}/green"
    www_blue_https     = "curl -L https://www.${var.domain_name}/blue"
    www_green_https    = "curl -L https://www.${var.domain_name}/green"
    
    # HTTP Redirect Testing
    http_redirect_test = "curl -I http://${var.domain_name}/blue # Should return 301 redirect"
    www_redirect_test  = "curl -I http://www.${var.domain_name}/blue # Should return 301 redirect"
    
    # SSL Certificate Testing
    ssl_certificate_test = "openssl s_client -connect ${var.domain_name}:443 -servername ${var.domain_name}"
    ssl_details_curl     = "curl -vI https://${var.domain_name}/blue 2>&1 | grep -E 'SSL|TLS|certificate'"
    
    # ALB Direct Testing (useful for debugging)
    blue_app_alb_direct  = "curl -k https://${aws_lb.alb.dns_name}/blue"
    green_app_alb_direct = "curl -k https://${aws_lb.alb.dns_name}/green"
    
    # DNS Resolution Testing
    dns_lookup_root = "nslookup ${var.domain_name}"
    dns_lookup_www  = "nslookup www.${var.domain_name}"
    
    # Certificate Validation Testing
    cert_expiry_check = "openssl s_client -connect ${var.domain_name}:443 -servername ${var.domain_name} 2>/dev/null | openssl x509 -noout -dates"
  }
}

# ------------------------------------
# Health Check Information
# ------------------------------------

output "health_check_urls" {
  description = "Health check URLs for monitoring (HTTPS)"
  value = {
    blue_health_https  = "https://${var.domain_name}/blue"
    green_health_https = "https://${var.domain_name}/green"
    blue_health_alb    = "https://${aws_lb.alb.dns_name}/blue"
    green_health_alb   = "https://${aws_lb.alb.dns_name}/green"
  }
}

# ------------------------------------
# SSL/TLS Configuration Information
# ------------------------------------

output "ssl_configuration" {
  description = "SSL/TLS configuration details"
  value = {
    https_listener_port = 443
    http_listener_port  = 80
    ssl_policy         = "ELBSecurityPolicy-2016-08"
    certificate_arn    = aws_acm_certificate.tls_cert.arn
    redirect_enabled   = true
    redirect_status    = "HTTP_301"
  }
}

# ------------------------------------
# Resource Summary
# ------------------------------------

output "deployment_summary" {
  description = "Summary of deployed resources with SSL/TLS"
  value = {
    vpc_id                = module.vpc.vpc_id
    alb_dns              = aws_lb.alb.dns_name
    domain_name          = var.domain_name
    ssl_certificate_arn  = aws_acm_certificate.tls_cert.arn
    blue_instance        = aws_instance.blue.id
    green_instance       = aws_instance.green.id
    public_subnets       = length(module.vpc.public_subnet_ids)
    private_subnets      = length(module.vpc.private_subnet_ids)
    target_groups        = 2
    security_groups      = 2
    https_enabled        = true
    http_redirect_enabled = true
  }
}

# ------------------------------------
# Quick Access URLs
# ------------------------------------

output "quick_access" {
  description = "Quick access URLs for testing"
  value = {
    blue_app  = "https://${var.domain_name}/blue"
    green_app = "https://${var.domain_name}/green"
    
    # Note: Use these if you want to test without SSL certificate validation
    blue_app_alb_insecure  = "curl -k https://${aws_lb.alb.dns_name}/blue"
    green_app_alb_insecure = "curl -k https://${aws_lb.alb.dns_name}/green"
  }
}