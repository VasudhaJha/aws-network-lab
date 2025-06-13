# 01-vpc-subnet

## Overview

This lab creates a foundation VPC with multiple subnets distributed across availability zones.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.0+)
- Basic understanding of AWS VPC concepts

## Architecture

![VPC Architecture](./01-vpc.drawio.png)

- **VPC**: Custom CIDR block with DNS resolution enabled
- **Subnets**: One per AZ, automatically calculated with non-overlapping CIDRs
- **Distribution**: Subnets spread across AZs for high availability

> **Note**: These are private subnets by default. Internet access will be configured in the next lab.

## You’ll Learn

- How to define a custom VPC with essential networking options
- How to use **Terraform data sources** to fetch AWS availability zones dynamically
- How to dynamically create subnets across Availability Zones
- How to use Terraform's `cidrsubnet()` to calculate non-overlapping CIDRs for subnets within VPC
- How to use `for_each` loops with local values for dynamic resource creation
- Best practices for tagging AWS resources

## Resources You'll Create

- 1 VPC with a custom CIDR block
- Multiple subnets distributed across Availability Zones (quantity controlled by num_subnets variable)

> **Note**: These are private subnets by default. Internet access will be configured in the next lab.

## Example Usage

Create a `terraform.tfvars` file:

```hcl
vpc_cidr = "10.0.0.0/16"
vpc_name = "my-lab-vpc"
num_subnets = 3
tags = {
  Environment = "lab"
  Project     = "aws-networking"
}
```

## Deployment

```bash
cd 01-vpc-subnet
terraform init
terraform plan
terraform apply
```

## What Gets Created

After running `terraform apply`, you'll see outputs similar to:

```text
Outputs:

subnet_cidrs = [
  "10.0.0.0/24",
  "10.0.1.0/24",
]
subnet_ids = [
  "subnet-053a48402cf1c8186",
  "subnet-0534fc90b7ad26333",
]
vpc_id = "vpc-0ee5aeb619a2d1357"
```

Here's how the resource map looks in the console:

![Resource Map](./resource_map.png)

Notice how there are no internet connections to anywhere. The default route table just allows for communication within the VPC.

## Cleanup

```bash
terraform destroy
```

## Next Steps

- **02-public-routing**: Add internet connectivity to make subnets public
- **03-private-routing**: Configure custom route tables
