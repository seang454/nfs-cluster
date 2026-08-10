# terraform.tfvars — seang.shop

############################################
# Auth / account / zone
############################################

cloudflare_api_token = "" # leave blank — export CLOUDFLARE_API_TOKEN instead
account_id            = "d63807fac3b90d92ab0e8bf0c211d79e"  # Cloudflare dashboard → seang.shop → Overview → Account ID
zone_id               = "25794f1056c9f59652052d977bd73acb"      # Cloudflare dashboard → seang.shop → Overview → Zone ID
domain                = "seang.shop"

############################################
# Origin
############################################

origin_ip             = "34.124.215.126" # public IP of the server running Nextcloud
additional_origin_ips = []

############################################
# DNS
############################################

dns_records = {
  nextcloud_pro = {
    name    = "nextcloud-pro"                    # becomes nextcloud-pro.seang.shop
    type    = "A"
    content = "34.124.215.126"  # same IP as origin_ip
    proxied = false
  }
  nextcloud_test = {
    name    = "nextcloud-test"                   # becomes nextcloud-test.seang.shop
    type    = "A"
    content = "34.124.215.126"  # same IP as origin_ip
    proxied = false
  }
  minio_pro = {
    name    = "minio-pro"                       # becomes minio-pro.seang.shop
    type    = "A"
    content = "34.124.215.126"
    proxied = false
  }
  minio_test = {
    name    = "minio-test"                      # becomes minio-test.seang.shop
    type    = "A"
    content = "34.124.215.126"
    proxied = false
  }
}

############################################
# SSL/TLS
############################################

ssl_mode          = "strict" # use "full" instead if your origin doesn't have HTTPS set up yet
min_tls_version   = "1.2"
always_use_https  = true
enable_hsts       = true

############################################
# WAF / Firewall
############################################

waf_managed_rules_enabled = true
office_ip_allowlist       = ["198.51.100.0/24"] # replace with your real office/VPN CIDR, or set to []
blocked_countries         = ["RU", "CN", "KP"]
block_tor                 = true
blocked_asns               = []

############################################
# Cache
############################################

browser_cache_ttl      = 14400
edge_cache_ttl          = 7200
cache_everything_paths  = ["/static/*", "/assets/*", "/images/*"]

############################################
# Rate limiting
############################################

rate_limited_paths = {
  nextcloud_login = {
    path                = "/login"
    requests_per_period = 20
    period_seconds      = 60
    mitigation_timeout  = 600
  }
}

############################################
# Load Balancer (Pro+ plan required)
############################################

enable_load_balancer   = false
load_balancer_hostname = "app"

############################################
# Cloudflare Tunnel
############################################

enable_tunnel = false # set true + fill tunnel_ingress_rules only if Nextcloud runs inside a K8s cluster
tunnel_name   = "k8s-tunnel"

tunnel_ingress_rules = {}

############################################
# Zero Trust / Access
############################################

enable_zero_trust            = false
access_allowed_email_domains = ["seang.shop"]
access_protected_apps        = ["admin", "vault", "prometheus"]

google_oauth_client_id     = ""
google_oauth_client_secret = ""
github_oauth_client_id     = ""
github_oauth_client_secret = ""

############################################
# Workers
############################################

enable_workers       = false
worker_route_pattern = "seang.shop/edge/*"

############################################
# Pages
############################################

enable_pages             = false
pages_project_name       = "frontend"
pages_production_branch  = "main"

############################################
# Origin CA
############################################

enable_origin_ca    = true
origin_ca_hostnames = ["seang.shop", "*.seang.shop"]