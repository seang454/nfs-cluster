# Cloudflare Origin CA certificate — installs on your origin server (e.g.
# nginx-ingress / cert-manager) so traffic between Cloudflare and the origin
# is encrypted, matching "Full (Strict)" SSL mode.

resource "tls_private_key" "origin" {
  count     = var.enable_origin_ca ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "origin" {
  count           = var.enable_origin_ca ? 1 : 0
  private_key_pem = tls_private_key.origin[0].private_key_pem

  subject {
    common_name = var.domain
  }
}

resource "cloudflare_origin_ca_certificate" "this" {
  count              = var.enable_origin_ca ? 1 : 0
  csr                = tls_cert_request.origin[0].cert_request_pem
  hostnames          = length(var.origin_ca_hostnames) > 0 ? var.origin_ca_hostnames : [var.domain, "*.${var.domain}"]
  request_type       = "origin-rsa"
  requested_validity = 5475 # 15 years, the max Cloudflare allows
}

# Store the private key + cert in Kubernetes as a TLS secret via a rendered
# manifest, or feed them to cert-manager / your ingress controller directly.
output "origin_ca_private_key_pem" {
  value       = var.enable_origin_ca ? tls_private_key.origin[0].private_key_pem : null
  sensitive   = true
  description = "Origin private key — install alongside the issued cert on your origin server."
}

output "origin_ca_certificate_pem" {
  value       = var.enable_origin_ca ? cloudflare_origin_ca_certificate.this[0].certificate : null
  sensitive   = true
  description = "Issued Cloudflare Origin CA certificate PEM."
}
