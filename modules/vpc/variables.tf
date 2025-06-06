variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "custom-vpc"
}

variable "num_private_subnets" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "num_public_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map()
  default     = {
    project = "networking-lab"
    env     = "dev"
  }
}
