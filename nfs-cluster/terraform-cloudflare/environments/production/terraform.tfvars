environment = "production"
domain      = "example.com"

waf_managed_rules_enabled = true
blocked_countries         = ["RU", "CN", "KP"]
block_tor                 = true

enable_load_balancer = true
enable_zero_trust     = true
enable_workers         = true
enable_pages            = true
enable_origin_ca        = true

edge_cache_ttl     = 14400
browser_cache_ttl  = 14400

access_protected_apps = ["admin", "vault", "prometheus", "grafana"]
