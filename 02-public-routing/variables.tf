variable "region" {
  description = "AWS region to provision and manage resources in"
  type        = string
}

variable "tags" {
  description = "Tags for this project resources"
  type        = map(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range of the VPC"
  type        = string
}

variable "num_subnets" {
  description = "Number of subnets to be created within the VPC"
  type        = string
  validation {
    condition = var.num_subnets > 0 && var.num_subnets < 16
    error_message = "Number of subnets must be between 1 and 16"
  }
}

variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

variable "public_route_table_name" {
  description = "Name of the Public Route Table"
  type        = string
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend VPC CIDR for subnets"
  type        = number
  default     = 8
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}