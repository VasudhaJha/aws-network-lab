# 03-private-routing

This section sets up **private subnets** in multiple Availability Zones with a **NAT Gateway**, allowing instances in private subnets to access the internet for tasks like installing packages, fetching updates, or calling external APIs without being exposed to incoming internet traffic.

---

## Pre-reads

- [AWS Docs: NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [Example: VPC with servers in private subnets and NAT](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-example-private-subnets-nat.html)
- [What is an Elastic IP?](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

## What You'll Learn

- How to dynamically create private subnets across AZs  
- How to set up a NAT Gateway and associate it with an Elastic IP (EIP)  
- How to route private subnet traffic through the NAT for secure outbound internet access  

---

## Resources Created

- Custom VPC
- Internet Gateway (required for NAT to work)
- Private Subnets (in dynamic AZs)
- Elastic IP (for NAT Gateway)
- NAT Gateway
- Route Table for private subnets
- Route Table Associations

---

## How to Verify It Works

We’ll test this setup in the next section by adding a **Bastion Host** in a public subnet. It will act as a jump box to access EC2 instances inside the private subnets.

Once that’s in place, we’ll launch a test EC2 instance in a private subnet and SSH into it through the Bastion Host. From there, we’ll confirm that outbound internet access works through the NAT Gateway using:

```bash
curl https://www.google.com
sudo yum update -y   # or sudo apt-get update for Ubuntu
```
