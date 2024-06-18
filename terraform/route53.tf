resource "aws_route53_record" "flowise" {
  zone_id = var.route53_hosted_zone_id
  name    = "flowise.${var.route53_hosted_zone_domain}"
  type    = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}