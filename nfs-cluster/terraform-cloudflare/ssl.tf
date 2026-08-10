# TLS encryption mode: off | flexible | full | strict
resource "cloudflare_zone_setting" "ssl_mode" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = var.ssl_mode
}

# Force HTTPS
resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = var.always_use_https ? "on" : "off"
}

# Minimum TLS version accepted at the edge
resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = var.min_tls_version
}

# TLS 1.3
resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id    = var.zone_id
  setting_id = "tls_1_3"
  value      = "on"
}

# Automatic HTTPS Rewrites (rewrites http:// links in HTML to https://)
resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = var.zone_id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

# Opportunistic Encryption
resource "cloudflare_zone_setting" "opportunistic_encryption" {
  zone_id    = var.zone_id
  setting_id = "opportunistic_encryption"
  value      = "on"
}

# HSTS
resource "cloudflare_zone_setting" "security_header" {
  count      = var.enable_hsts ? 1 : 0
  zone_id    = var.zone_id
  setting_id = "security_header"

  value = {
    strict_transport_security = {
      enabled            = true
      max_age            = 31536000
      include_subdomains = true
      preload             = true
      nosniff              = true
    }
  }
}
