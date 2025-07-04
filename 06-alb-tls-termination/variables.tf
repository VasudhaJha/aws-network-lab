# ------------------------------------
# Regional Configuration
# ------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

# ------------------------------------
# VPC Configuration Variables
# ------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "alb-tls-termination-lab-vpc"
}

variable "num_public_subnets" {
  description = "Number of public subnets to create (ALB requires at least 2 AZs)"
  type        = number
  default     = 2

  validation {
    condition     = var.num_public_subnets >= 2
    error_message = "Application Load Balancer requires at least 2 public subnets in different AZs."
  }
}

variable "num_private_subnets" {
  description = "Number of private subnets to create for EC2 instances"
  type        = number
  default     = 2

  validation {
    condition     = var.num_private_subnets >= 2
    error_message = "At least 2 private subnets are required for blue and green instances."
  }
}

# ------------------------------------
# EC2 Configuration
# ------------------------------------

variable "instance_type" {
  description = "EC2 instance type for blue and green servers"
  type        = string
  default     = "t2.micro"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map
}

# ------------------------------------
# Load Balancer Configuration
# ------------------------------------

variable "alb_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout (seconds)"
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout must be between 2 and 120 seconds."
  }
}

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks before considering target healthy"
  type        = number
  default     = 2

  validation {
    condition     = var.healthy_threshold >= 2 && var.healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks before considering target unhealthy"
  type        = number
  default     = 2

  validation {
    condition     = var.unhealthy_threshold >= 2 && var.unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "alb_ingress_ports" {
  description = "Ports from which inbound traffic is allowed on the ALB"
  type = list(string)
}

# ------------------------------------
# Route53 Configuration
# ------------------------------------

variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = "aws-network-lab.com"
}

# ------------------------------------
# Application Configuration
# ------------------------------------

variable "blue_app_path" {
  description = "URL path for blue application routing"
  type        = string
  default     = "/blue"
}

variable "green_app_path" {
  description = "URL path for green application routing" 
  type        = string
  default     = "/green"
}