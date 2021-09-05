variable "domain" { type = string }

# create route53 zone
resource "aws_route53_zone" "primary" {
  name = var.domain

  tags = {
    Name = "${var.project}-${terraform.workspace}-route53-zone"
  }
}

# Route url to load balancer
resource "aws_route53_record" "route53_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${terraform.workspace}.${var.project}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}
