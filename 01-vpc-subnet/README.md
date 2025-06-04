# 01-vpc-subnet

This module sets up a basic VPC and a single public subnet in AWS using Terraform.

## What You’ll Learn

- How to define a custom VPC
- How to create a subnet inside that VPC
- How CIDR blocks work in Terraform

## Resources Created

- 1 VPC with a custom CIDR
- 1 Subnet within the VPC

## How to Use

```bash
terraform init
terraform plan
terraform apply
```

To destroy the resources:

```bash
terraform destroy
```
