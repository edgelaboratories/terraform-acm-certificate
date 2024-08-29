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

# Conditionally create the Route 53 record (skipped if validate_route53 is false)
resource "aws_route53_record" "verify" {
  count = var.validate_route53 ? length(local.dvo_list) : 0

  name    = local.dvo_list[count.index].resource_record_name
  records = [local.dvo_list[count.index].resource_record_value]
  type    = local.dvo_list[count.index].resource_record_type
  zone_id = var.zone_id
  ttl     = 60
}

# Create the certificate validation, even if Route 53 records are not created
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = var.validate_route53 ? aws_route53_record.verify[*].name : [for dvo in local.dvo_list : dvo.resource_record_name]
}

output "arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}
