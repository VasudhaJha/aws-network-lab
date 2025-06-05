# AWS Network Lab with Terraform

This repository is a hands-on learning lab for mastering AWS networking concepts using Terraform.  
Each concept is isolated into its own folder so you can build, test, and destroy infrastructure incrementally.

## Learning Roadmap

| #  | Module Folder                     | What You'll Learn                                                                 |
|----|----------------------------------|-----------------------------------------------------------------------------------|
| 01 | `01-vpc-subnet/`                 | Create a custom VPC and dynamically generate subnets using AZs & CIDRs           |
| 02 | `02-public-routing/`            | Make subnets public using IGW, route tables, and test with EC2 + curl            |
| 03 | `03-private-routing/`           | Set up private subnets and NAT Gateway for outbound internet access              |
| 04 | `04-security-groups/`           | Configure security groups using best practices with ingress and egress rules     |
| 05 | `05-elb-setup/`                 | Deploy an Application Load Balancer with target groups and listeners             |
| 06 | `06-dns-route53-basics/`        | Use Route 53 to manage domain names, records, and routing policies               |
| 07 | `07-alb-tls-termination/`       | Attach an ACM TLS certificate to ALB to enable HTTPS access                      |
| 08 | `08-waf-protection/`            | Add AWS WAF to filter malicious traffic at the ALB layer                         |
| 09 | `09-nlb-setup/`                 | Create a Network Load Balancer for TCP/TLS-based workloads                       |
| 10 | `10-cloudfront-s3/`      | Serve static websites with CloudFront + S3 and add TLS termination at the edge   |

---

## Folder Structure

Each folder is numbered in order of complexity. You can run each folder independently using `terraform init`, `plan`, and `apply`.

## How to Use

Inside each subfolder:

```bash
terraform init
terraform plan
terraform apply 
```

To tear everything down:

```bash
terraform destroy
```

Each module is designed to be self-contained and safe to destroy.
