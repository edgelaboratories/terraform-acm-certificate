# Request a certificate for the specified domain name.
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = var.use_transparency_logging ? "ENABLED" : "DISABLED"
  }

  tags = {
    Name = var.name
  }
}

locals {
  dvo_list = [for dvo in aws_acm_certificate.this.domain_validation_options : dvo]
}

# Conditionally create the Route 53 record
resource "aws_route53_record" "verify" {
  count = var.create_record ? length(local.dvo_list) : 0

  name    = local.dvo_list[count.index].resource_record_name
  records = [local.dvo_list[count.index].resource_record_value]
  type    = local.dvo_list[count.index].resource_record_type
  zone_id = var.zone_id
  ttl     = 60
}

# Conditionally wait for the certificate to be issued
resource "aws_acm_certificate_validation" "this" {
  count = var.create_record ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = aws_route53_record.verify[*].name
}

output "arn" {
  value = var.create_record && length(aws_acm_certificate_validation.this) > 0 ? aws_acm_certificate_validation.this[0].certificate_arn : null
}
