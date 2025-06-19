terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.99"
    }
  }
  required_version = ">=1.11.4"
}

provider "aws" {
  region = var.region
}