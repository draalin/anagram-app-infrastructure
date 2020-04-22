# Route53 (DNS)
data "aws_route53_zone" "selected" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "FrontendDNSRecord" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "A"
  alias {
    name                   = "dualstack.${var.aws_alb}."
    zone_id                = "Z35SXDOTRQ7X7K"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "FrontendWWWDNSRecord" {
  name    = "www.${data.aws_route53_zone.selected.name}"
  zone_id = data.aws_route53_zone.selected.zone_id
  type    = "CNAME"
  ttl     = 3600
  records = [var.domain_name]
}


resource "aws_route53_record" "BastionDNSRecord" {
  name    = "bastion.${data.aws_route53_zone.selected.name}"
  zone_id = data.aws_route53_zone.selected.zone_id
  type    = "CNAME"
  ttl     = 3600
  records = [var.bastion_public_dns]
}
