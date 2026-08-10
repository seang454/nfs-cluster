# Custom firewall / security rules via the ruleset engine
# (this is the modern replacement for the old cloudflare_firewall_rule)

locals {
  country_block_expr = length(var.blocked_countries) > 0 ? join(" or ", [
    for c in var.blocked_countries : "ip.geoip.country eq \"${c}\""
  ]) : "false"

  asn_block_expr = length(var.blocked_asns) > 0 ? join(" or ", [
    for asn in var.blocked_asns : "ip.geoip.asnum eq ${asn}"
  ]) : "false"

  office_allow_expr = length(var.office_ip_allowlist) > 0 ? join(" or ", [
    for cidr in var.office_ip_allowlist : "ip.src in {${cidr}}"
  ]) : "false"
}

resource "cloudflare_ruleset" "custom_firewall" {
  zone_id = var.zone_id
  name    = "Custom firewall rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = concat(
    [
      {
        action      = "skip"
        expression  = local.office_allow_expr
        description = "Allow office / VPN egress IPs"
        enabled     = length(var.office_ip_allowlist) > 0
        action_parameters = {
          ruleset = "current"
        }
      },
      {
        action      = "block"
        expression  = local.country_block_expr
        description = "Block traffic from disallowed countries"
        enabled     = length(var.blocked_countries) > 0
      },
      {
        action      = "block"
        expression  = "(cf.threat_score > 30)"
        description = "Block known malicious User-Agents / high threat score"
        enabled     = true
      },
    ],
    # Note: $cf.anonymizer.tor_exit_nodes requires a paid Cloudflare plan.
    # Upgrade to Pro or Business to re-enable Tor blocking.
    length(var.blocked_asns) > 0 ? [
      {
        action      = "block"
        expression  = local.asn_block_expr
        description = "Block specific ASNs"
        enabled     = true
      }
    ] : []
  )
}
