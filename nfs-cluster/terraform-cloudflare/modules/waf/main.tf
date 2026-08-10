resource "cloudflare_ruleset" "managed" {
  zone_id = var.zone_id
  name    = var.name
  kind    = "zone"
  phase   = "http_request_firewall_managed"

  rules = concat(
    [
      {
        action = "execute"
        action_parameters = {
          id = "efb7b8c949ac4650a09736fc376e9aee" # Cloudflare Managed Ruleset
        }
        expression  = "true"
        description = "Execute Cloudflare Managed Ruleset"
        enabled     = true
      }
    ],
    var.enable_owasp ? [
      {
        action = "execute"
        action_parameters = {
          id = "4814384a9e5d4991b9815dcfc25d2f1f" # OWASP Core Ruleset
        }
        expression  = "true"
        description = "Execute OWASP Core Ruleset"
        enabled     = true
      }
    ] : []
  )
}
