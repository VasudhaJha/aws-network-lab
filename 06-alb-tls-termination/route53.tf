# ------------------------------------
# Route53 Configuration
# ------------------------------------

/*
Looks up the existing public hosted zone for your domain.
Since I directly registered the domain directly with Route 53, AWS automatically created this hosted zone.
This data source allows Terraform to reference the hosted zone dynamically, without hardcoding the zone ID.
*/
data "aws_route53_zone" "my_zone" {
    name = var.domain_name
    private_zone = false
}

/*
Creates an Alias A record for the root domain (apex domain).
- This maps aws-network-lab.com directly to the ALB.
- Uses Alias (instead of CNAME) because:
  - Alias supports apex domains
  - Alias is AWS-native and integrates directly with AWS-managed resources like ALB
  - Faster DNS resolution with no extra lookup
- Alias requires:
  - ALB DNS name
  - ALB zone ID (provided by aws_lb resource)
*/

resource "aws_route53_record" "root_alias" {
  zone_id = data.aws_route53_zone.my_zone.id
  name = ""
  type = "A"

  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

/*
Creates an Alias A record for www subdomain
- Technically this could be a CNAME (since it's a subdomain),
  but Alias A is better for AWS-native resources because:
  - Faster resolution (no additional lookup)
  - Fully integrated with ALB
- Allows users to access www.aws-network-lab.com (optional, but common)
*/
resource "aws_route53_record" "www_alias" {
  zone_id = data.aws_route53_zone.my_zone.id
  name = "www"
  type = "A"

  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}