# AWS Networking Labs with Terraform

This repository is a **hands-on, project-based learning path** to master core AWS networking concepts using Terraform.

Each lab focuses on a specific building block, allowing you to incrementally build up a fully functional, production-grade AWS network architecture.

---

## Learning Roadmap

| #  | Module Folder               | What You'll Build & Learn |
|----|------------------------------|----------------------------|
| 01 | `01-vpc-subnet/`             | Create a custom VPC and dynamically provision subnets across AZs using CIDR calculations |
| 02 | `02-public-routing/`         | Make subnets publicly accessible using Internet Gateway (IGW), route tables, and verify with EC2 connectivity |
| 03 | `03-hybrid-networking/`         | Build hybrid VPC architecture: private subnets, NAT Gateway for outbound access, and secure Bastion host for SSH access |
| 04 | `04-application-load-balancing/` | Deploy an Application Load Balancer (ALB), configure target groups, listeners, and distribute traffic to EC2 instances |
| 05 | `05-route53-dns-integration/` | Integrate Route 53 DNS with ALB, manage hosted zones, create DNS records, and route traffic via custom domains |
| 06 | `06-alb-tls-termination/`    | Attach ACM-managed TLS certificates to ALB to enable HTTPS access |
| 07 | `07-waf-protection/`         | Add AWS WAF to protect applications from malicious traffic and common attack patterns |
| 08 | `08-network-load-balancer/`  | Build a Network Load Balancer (NLB) for TCP/TLS-based workloads with cross-zone balancing |
| 09 | `09-cloudfront-s3/`          | Deploy a static website using CloudFront + S3, with TLS termination at the edge for global content delivery |

---

## Who is this for?

- AWS learners who want real, hands-on experience beyond tutorials
- DevOps, Cloud Engineers, and SREs preparing for interviews or certifications
- Anyone who wants to deeply understand AWS networking components in isolation

---

## Key Concepts Covered

- VPC, Subnets, CIDR, Availability Zones
- Route Tables, Internet Gateways, NAT Gateway
- Bastion Hosts & Private Subnet Access
- Application Load Balancers (ALB) & Target Groups
- DNS with Route 53
- TLS Certificates with ACM
- AWS WAF & Web Application Security
- Network Load Balancers (NLB)
- CloudFront CDN with S3 Origin

---

## ⚠️ Cost Reminder

Some resources (NAT Gateway, ALB, WAF, CloudFront) may incur costs if left running. Always run `terraform destroy` after completing a lab.

---

👉 **More labs will be added as I continue building the full AWS Networking reference project.**
