# Browser + edge cache TTL, cache level, dev mode off
resource "cloudflare_zone_setting" "browser_cache_ttl" {
  zone_id    = var.zone_id
  setting_id = "browser_cache_ttl"
  value      = var.browser_cache_ttl
}

resource "cloudflare_zone_setting" "cache_level" {
  zone_id    = var.zone_id
  setting_id = "cache_level"
  value      = "aggressive"
}

resource "cloudflare_zone_setting" "development_mode" {
  zone_id    = var.zone_id
  setting_id = "development_mode"
  value      = "off"
}

# Cache Rules — ruleset-engine cache_everything for static asset paths,
# and one rule that ignores query strings on those same paths.
locals {
  cache_everything_expr = length(var.cache_everything_paths) > 0 ? join(" or ", [
    for p in var.cache_everything_paths : "starts_with(http.request.uri.path, \"${trimsuffix(p, "*")}\")"
  ]) : "false"
}

resource "cloudflare_ruleset" "cache_rules" {
  zone_id = var.zone_id
  name    = "Cache rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [
    {
      action      = "set_cache_settings"
      expression  = local.cache_everything_expr
      description = "Cache everything for static asset paths"
      enabled     = length(var.cache_everything_paths) > 0
      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = var.edge_cache_ttl
        }
        browser_ttl = {
          mode    = "override_origin"
          default = var.browser_cache_ttl
        }
      }
    },
    {
      action      = "set_cache_settings"
      expression  = local.cache_everything_expr
      description = "Ignore query strings for static asset paths"
      enabled     = length(var.cache_everything_paths) > 0
      action_parameters = {
        cache_key = {
          ignore_query_strings_order = true
          custom_key = {
            query_string = {
              exclude = { all = true }
            }
          }
        }
      }
    }
  ]
}
