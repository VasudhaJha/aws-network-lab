variable "region" {
  description = "AWS region to provision and manage resources in"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "num_subnets" {
  description = "Number of private subnets to create"
  type        = number
  validation {
    condition     = var.num_subnets > 0 && var.num_subnets <= 10
    error_message = "Number of subnets must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "EC2 instance type for bastion and private instances"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to the public key file for EC2 instance access"
  type        = string
  default     = "lab-key.pub"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  validation {
    condition     = contains(keys(var.tags), "project")
    error_message = "Tags must include a 'project' key for resource naming."
  }
}