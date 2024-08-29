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

# Check if the Route 53 record already exists
data "aws_route53_record" "existing_verify" {
  zone_id = var.zone_id
  name    = local.dvo.resource_record_name
  type    = local.dvo.resource_record_type
}

# Conditionally create the Route 53 record only if it doesn't already exist
resource "aws_route53_record" "verify" {
  count   = length(data.aws_route53_record.existing_verify.id) == 0 ? 1 : 0
  name    = local.dvo.resource_record_name
  records = [local.dvo.resource_record_value]
  type    = local.dvo.resource_record_type
  zone_id = var.zone_id
  ttl     = 60
}

# Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = aws_route53_record.verify[*].fqdn
}

output "arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}
