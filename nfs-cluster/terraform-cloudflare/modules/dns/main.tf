resource "cloudflare_dns_record" "this" {
  for_each = var.records

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  proxied  = contains(["A", "AAAA", "CNAME"], each.value.type) ? each.value.proxied : null
  ttl      = each.value.proxied ? 1 : each.value.ttl
  priority = each.value.priority
}
