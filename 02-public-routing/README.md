# 02-public-routing

This module builds on the previous VPC and subnet setup by making the subnets **publicly accessible**.

## What You’ll Learn

- What an Internet Gateway (IGW) is and when to use it
- How route tables enable traffic flow within a VPC
- How to add a route to allow internet access from subnets
- How to associate route tables with subnets to control their behavior
- How a “public subnet” is not just about IP assignment, but **routing**

## Resources Created

- 1 VPC with DNS settings enabled
- N Subnets distributed across Availability Zones
- 1 Internet Gateway attached to the VPC
- 1 Route Table with a route to `0.0.0.0/0` via the IGW
- N Route Table Associations to link each subnet to the public route

## How to Use

```bash
terraform init
terraform plan
terraform apply
```

To destroy resources

```bash
terraform destroy
```
