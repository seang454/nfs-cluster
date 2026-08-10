environment = "dev"
domain      = "dev.example.com"

waf_managed_rules_enabled = true
blocked_countries         = []   # keep dev open for testing from anywhere
block_tor                 = false

enable_load_balancer = false
enable_zero_trust    = false
enable_workers        = true
enable_pages           = true
enable_origin_ca       = true

edge_cache_ttl     = 300  # short cache in dev so changes show up fast
browser_cache_ttl  = 300
