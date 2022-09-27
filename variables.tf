variable "name" {
  description = "Pretty name of the record"
}

variable "domain_name" {
  description = "The domain name for which the certificate should be issued"
}

variable "zone_id" {
  description = "Route 53 hosted zone id. This is used for the validation record"
}

variable "use_transparency_logging" {
  description = <<EOF
Specifies whether certificate details should be added to a certificate transparency log.

See https://docs.aws.amazon.com/acm/latest/userguide/acm-concepts.html#concept-transparency for more details.
EOF
  default     = true
}
