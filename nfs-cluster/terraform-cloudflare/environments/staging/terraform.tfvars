environment = "staging"
domain      = "staging.example.com"

waf_managed_rules_enabled = true
blocked_countries         = ["RU", "KP"]
block_tor                 = true

enable_load_balancer = false
enable_zero_trust     = true
enable_workers         = true
enable_pages            = true
enable_origin_ca        = true

edge_cache_ttl     = 3600
browser_cache_ttl  = 3600
