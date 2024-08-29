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
  dvo = tolist(aws_acm_certificate.this.domain_validation_options)[0]
}

# Create unique record name based on the region
resource "aws_route53_record" "verify" {
  for_each = var.create_record_in_region ? { for r in [var.region] : r => r } : {}
  name     = local.dvo.resource_record_name
  records  = [local.dvo.resource_record_value]
  type     = local.dvo.resource_record_type
  zone_id  = var.zone_id
  ttl      = 60
}

# Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.verify : record.fqdn]
}

output "arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}
