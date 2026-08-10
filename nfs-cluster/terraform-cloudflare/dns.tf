############################################
# Root + www
############################################

resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = "@"
  type    = "A"
  content = var.origin_ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = var.zone_id
  name    = "www"
  type    = "CNAME"
  content = var.domain
  proxied = true
  ttl     = 1
}

############################################
# Wildcard (proxied wildcards need Cloudflare for SaaS on some plans —
# adjust `proxied` if your plan doesn't support it)
############################################

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.zone_id
  name    = "*"
  type    = "A"
  content = var.origin_ip
  proxied = true
  ttl     = 1
}

############################################
# Mail (MX + SPF/DMARC as TXT)
############################################

resource "cloudflare_dns_record" "mx" {
  count    = 0 # flip to 2 (or however many MX hosts you have) and fill in `content`
  zone_id  = var.zone_id
  name     = "@"
  type     = "MX"
  content  = "mail.example.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:_spf.google.com ~all"
  ttl     = 3600
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}"
  ttl     = 3600
}

############################################
# Verification / misc TXT, NS delegation example
############################################

resource "cloudflare_dns_record" "domain_verification" {
  zone_id = var.zone_id
  name    = "@"
  type    = "TXT"
  content = "cf-verify=REPLACE_ME"
  ttl     = 3600
}

# Example NS delegation for a subdomain to another DNS provider
resource "cloudflare_dns_record" "delegated_subdomain_ns" {
  count   = 0 # enable if you delegate a subdomain elsewhere
  zone_id = var.zone_id
  name    = "legacy"
  type    = "NS"
  content = "ns1.otherprovider.com"
  ttl     = 3600
}

############################################
# SRV example (e.g. Matrix federation)
############################################

resource "cloudflare_dns_record" "srv_matrix" {
  count   = 0
  zone_id = var.zone_id
  name    = "_matrix-fed._tcp"
  type    = "SRV"
  ttl     = 3600
  data = {
    service  = "_matrix-fed"
    proto    = "_tcp"
    name     = var.domain
    priority = 10
    weight   = 0
    port     = 8448
    target   = "matrix.${var.domain}"
  }
}

############################################
# CAA — restrict which CAs may issue certs for this domain
############################################

resource "cloudflare_dns_record" "caa_letsencrypt" {
  zone_id = var.zone_id
  name    = "@"
  type    = "CAA"
  ttl     = 3600
  data = {
    flags = 0
    tag   = "issue"
    value = "letsencrypt.org"
  }
}

resource "cloudflare_dns_record" "caa_cloudflare" {
  zone_id = var.zone_id
  name    = "@"
  type    = "CAA"
  ttl     = 3600
  data = {
    flags = 0
    tag   = "issue"
    value = "digicert.com"
  }
}

############################################
# Additional records driven by var.dns_records
# (covers gitlab / jenkins / argocd / grafana / prometheus / vault / etc.)
############################################

resource "cloudflare_dns_record" "additional" {
  for_each = var.dns_records

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.type == "A" || each.value.type == "AAAA" || each.value.type == "CNAME" ? each.value.proxied : null
  ttl      = each.value.proxied ? 1 : each.value.ttl
  priority = each.value.priority
}
