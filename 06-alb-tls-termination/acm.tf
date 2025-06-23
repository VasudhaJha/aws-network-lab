/*
------------------------------------
ACM Certificate Request
------------------------------------

- Requests a public SSL/TLS certificate from AWS Certificate Manager (ACM).
- The primary domain name comes from the input variable var.domain_name.

- Also includes www.<domain> as an additional domain using Subject Alternative Names (SANs).

- Validation method is set to DNS, which means ACM will give DNS records you need to create to prove domain ownership.

- The lifecycle rule ensures Terraform creates the new certificate before destroying old one (safe replacement during updates).
*/


resource "aws_acm_certificate" "tls_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

/*
------------------------------------
Route53 DNS Validation Records
------------------------------------

- Creates Route53 DNS records automatically for validating domain ownership for ACM.

- ACM gives a list of domain_validation_options, one for each domain name (main + SANs).

- We loop over these using for_each to create required CNAME records.

- These records prove to Amazon’s Certificate Authority that you control these domains.

- The records are placed inside the correct hosted zone my_zone.
*/

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.tls_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.my_zone.id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

/*
------------------------------------
ACM Certificate Validation Completion
------------------------------------

This resource tells Terraform to wait until ACM validates the domain ownership and successfully issues the certificate.

It ties together the ACM certificate and the DNS records.

Terraform will not proceed until ACM confirms validation is complete.

The validation_record_fqdns list collects the FQDNs of all the created DNS records so ACM knows where to check for validation.
*/
resource "aws_acm_certificate_validation" "cert_validation_complete" {
  certificate_arn         = aws_acm_certificate.tls_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
