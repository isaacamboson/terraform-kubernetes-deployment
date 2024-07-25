locals {
  PublicPrefix      = "Public"
  PrivatePrefix     = "Private"
  ApplicationPrefix = "clixx-k8s"
  
  inbound_ports     = [80, 443, 8080, 22]

  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

# route53 for clixx application
resource "aws_route53_record" "clixx_route53" {
  zone_id = data.aws_route53_zone.stack_isaac_zone.id
  name    = "clixx"
  # name    = "dev.clixx"
  type = "A"
  # ttl     = 5

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_lb.lb]
}

