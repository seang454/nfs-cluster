resource "cloudflare_ruleset" "rate_limiting" {
  zone_id = var.zone_id
  name    = "Rate limiting rules"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    for key, rl in var.rate_limited_paths : {
      action      = "block"
      # Free plan: use 'contains' instead of 'matches' (matches requires Business plan)
      expression  = "http.request.uri.path contains \"${trimsuffix(rl.path, "/*")}\""
      description = "Rate limit ${key}: ${rl.requests_per_period} req / ${rl.period_seconds}s"
      enabled     = true
      action_parameters = {
        response = {
          status_code  = 429
          content      = "{\"error\":\"rate limited, try again later\"}"
          content_type = "application/json"
        }
      }
      ratelimit = {
        characteristics     = ["ip.src", "cf.colo.id"]
        # Free plan only supports period = 10 seconds
        period              = 10
        requests_per_period = rl.requests_per_period
        # Free plan only supports mitigation_timeout = 10 seconds
        mitigation_timeout  = 10
        requests_to_origin  = false
      }
    }
  ]
}
