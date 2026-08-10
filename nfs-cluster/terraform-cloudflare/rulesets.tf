# Generic ruleset-engine helpers that don't fit neatly into waf.tf / cache.tf,
# e.g. request header transforms, redirects, and origin rules.
#
# NOTE: Both resources below require a paid Cloudflare plan (Pro or higher).
# Set enable_paid_features = true in terraform.tfvars once you upgrade.

resource "cloudflare_ruleset" "http_request_transform" {
  count   = var.enable_paid_features ? 1 : 0
  zone_id = var.zone_id
  name    = "Request header transform"
  kind    = "zone"
  phase   = "http_request_transform"

  rules = [
    {
      action      = "rewrite"
      expression  = "true"
      description = "Add a client-facing request id header"
      enabled     = true
      action_parameters = {
        headers = {
          "X-Request-Source" = {
            operation = "set"
            value     = "cloudflare-edge"
          }
        }
      }
    }
  ]
}

resource "cloudflare_ruleset" "redirects" {
  count   = var.enable_paid_features ? 1 : 0
  zone_id = var.zone_id
  name    = "Redirects"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [
    {
      action      = "redirect"
      expression  = "http.host eq \"www.${var.domain}\""
      description = "Redirect www to apex — remove if you'd rather keep www canonical"
      enabled     = false
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://${var.domain}\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
    }
  ]
}
