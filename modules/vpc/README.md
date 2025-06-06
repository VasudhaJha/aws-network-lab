# VPC Module

This module provisions a custom VPC with both **private** and **public** subnets, a **NAT Gateway**, and proper **routing** for internet access.

---

## Features

- Creates a VPC with DNS support and hostname resolution
- Dynamically creates private and public subnets across Availability Zones
- Adds a public subnet with Internet Gateway access
- Creates a NAT Gateway in a public subnet for outbound access from private subnets
- Configures route tables and associations for both subnet types
- Outputs all core resource IDs for reuse

---

## Resources Created

- `aws_vpc`
- `aws_internet_gateway`
- `aws_subnet` (private and public)
- `aws_eip` (for NAT Gateway)
- `aws_nat_gateway`
- `aws_route_table` and `aws_route_table_association`

---

## Input Variables

| Name                | Description                                 | Type          | Default               |
|---------------------|---------------------------------------------|----------------|------------------------|
| `vpc_cidr`          | CIDR block for the VPC                      | `string`       | `"10.0.0.0/16"`        |
| `vpc_name`          | Name tag for the VPC                        | `string`       | `"custom-vpc"`         |
| `num_private_subnets` | Number of private subnets to create        | `number`       | `2`                    |
| `num_public_subnets`  | Number of public subnets to create         | `number`       | `1`                    |
| `tags`              | Common tags for all resources               | `map(string)`  | `{ project = "...", env = "..." }` |

---

## Outputs

| Name                | Description                                  |
|---------------------|----------------------------------------------|
| `vpc_id`            | ID of the created VPC                        |
| `private_subnet_ids`| List of private subnet IDs                   |
| `public_subnet_ids` | List of public subnet IDs                    |
| `nat_gateway_id`    | ID of the NAT Gateway                        |
| `igw_id`            | ID of the Internet Gateway                   |

---

## Usage Example

```hcl
module "vpc" {
  source              = "../modules/vpc"
  vpc_cidr            = "10.0.0.0/16"
  num_private_subnets = 2
  num_public_subnets  = 1
  vpc_name            = "dev-vpc"
  tags = {
    project = "networking-lab"
    env     = "dev"
  }
}
```
