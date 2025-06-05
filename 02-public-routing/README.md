# 02-public-routing

This module builds on the previous VPC and subnet setup by making the subnets **publicly accessible**. It verifies internet access by launching a basic web server in one of the subnets.

## What You’ll Learn

- How to make subnets publicly accessible by attaching an Internet Gateway
- How to define a route table with a route to `0.0.0.0/0` and associate it with subnets
- How to dynamically create multiple subnets across Availability Zones
- How to launch an EC2 instance inside a public subnet
- How to use a user data script to install a web server (NGINX or Apache) on EC2
- How to allow HTTP (port 80) and SSH (port 22) access using security groups
- How to verify internet access to your instance using `curl` and its public IP

## Resources Created

- 1 VPC with DNS settings enabled
- N Subnets distributed across Availability Zones
- 1 Internet Gateway attached to the VPC
- 1 Route Table with a route to `0.0.0.0/0` via the IGW
- N Route Table Associations to link each subnet to the public route
- 1 EC2 instance with NGINX or Apache pre-installed using user data
- 1 Security Group allowing inbound HTTP (80)

## How to Use

```bash
terraform init
terraform plan
terraform apply
```

## How to Test

After apply:

Copy the public IP output

Run:

```bash
curl http://<public-ip>
```

If you see HTML from NGINX or Apache → your public subnet setup works.

## To destroy resources

```bash
terraform destroy
```
