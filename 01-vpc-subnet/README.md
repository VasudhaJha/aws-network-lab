# 01-vpc-subnet

This module sets up a basic VPC and **multiple subnets** in AWS using Terraform.

## You’ll Learn

- How to define a custom VPC with essential networking options
- How to use **Terraform data sources** to fetch AWS availability zones dynamically
- How to dynamically create subnets across Availability Zones
- How to use `cidrsubnet()` to calculate non-overlapping CIDRs for subnets within VPC

## Visual Overview

<details>
<summary><strong>View Architecture Diagram</strong></summary>

```text
                         +----------------------------+
                         |         AWS Region        |
                         |      (e.g., ap-south-1)    |
                         +------------+---------------+
                                      |
                               +------+------+
                               |     VPC      |
                               |   (Custom)   |
                               +------+-------+
                                      |
        +-----------------------------+-----------------------------+
        |                             |                             |
+---------------+           +---------------+             +---------------+
|    Subnet     |           |    Subnet     |     ...     |    Subnet     |
|    (AZ-a)     |           |    (AZ-b)     |             |    (AZ-c)     |
+---------------+           +---------------+             +---------------+
</details> ```

## Resources You'll Create

- 1 VPC with a custom CIDR block
- N subnets in different Availability Zones within the VPC (1 per AZ, as defined by input)

> Note: Subnets are created dynamically based on `var.num_subnets` and the region’s available AZs.
> You will learn how to make the subnets public in next section. For now, no requests can come in or go out from these subnets.

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
