# Certificates generator using AWS Certificate Manager and Route 53

This module allows you to generate a certificate using AWS Certificate Manager,
and validate it using a Route 53 zone ID that you control.

For example, assuming that:

* You control a Route 53 zone for `example.com`
* You want to generate a certificate for the domain: `toto.plop.example.com`

You can use this module as follow:

```hcl
data "aws_route53_zone" "example" {
  name = "example.com"
}

module "my_certificate" {
  source = "git@github.com:edgelaboratories/terraform-modules.git//acm-certificate?ref=v9"

  stack_id                 = "my-stack"
  name                     = "Toto Certificate"
  domain_name              = "toto.plop.${data.aws_route53_zone.public.name}"
  zone_id                  = data.aws_route53_zone.example.zone_id
  use_transparency_logging = false
}
```

You can use the `arn` output to access the ARN of the generated certificate.
