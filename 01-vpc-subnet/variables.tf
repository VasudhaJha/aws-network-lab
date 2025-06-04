variable "region" {
  description = "AWS region to provision and manage resources in"
  type = string
}

variable "tags" {
  description = "Tags for this project resources"
  type = map(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR range of the VPC"
  type = string
}

variable "num_subnets" {
  description = "Number of subnets to be created within the VPC"
  type = string
}