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

# Register records to prove we own the domain name
resource "aws_route53_record" "verify" {
  # Following this
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-3-upgrade#resource-aws_acm_certificate
  # I would expect this to work:

  # for_each = {
  #   for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
  #     name   = dvo.resource_record_name
  #     record = dvo.resource_record_value
  #     type   = dvo.resource_record_type
  #   }
  # }

  # name    = each.value.name
  # records = [each.value.record]
  # type    = each.value.type
  # zone_id = var.zone_id
  # ttl     = 60

  # But it doesn't, so I just copied https://github.com/terraform-providers/terraform-provider-aws/issues/14447
  name    = local.dvo.resource_record_name
  records = [local.dvo.resource_record_value]
  type    = local.dvo.resource_record_type
  zone_id = var.zone_id
  ttl     = 60
}

# Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  # validation_record_fqdns = [for record in aws_route53_record.verify : record.fqdn]
  validation_record_fqdns = aws_route53_record.verify[*].fqdn
}

output "arn" {
  # Output the certificate only once it has been validated.
  #
  # Otherwise, Terraform may try to feed the certificate ARN to another
  # resource (such as a load-balancer listener), which may be rejected because
  # the certificate is not valid:
  #
  #   UnsupportedCertificate: The certificate 'XXX' must have a fully-qualified
  #   domain name, a supported signature, and a supported key size.
  value = aws_acm_certificate_validation.this.certificate_arn
}
