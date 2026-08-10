############################################
# Auth / account / zone
############################################

variable "cloudflare_api_token" {
  description = "Cloudflare API token (scoped, not the legacy Global API Key). Leave blank to use the CLOUDFLARE_API_TOKEN environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID for the primary domain."
  type        = string
}

variable "domain" {
  description = "Root domain managed in this zone, e.g. example.com."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, staging, or production."
  type        = string
  default     = "dev"
}

variable "enable_paid_features" {
  description = "Enable features that require a paid Cloudflare plan (Pro or higher): Managed WAF, Bot Management, Transform Rules, Dynamic Redirects."
  type        = bool
  default     = false
}

############################################
# Origin
############################################

variable "origin_ip" {
  description = "Primary origin IP address (e.g. ingress / load balancer IP)."
  type        = string
  default     = "203.0.113.10"
}

variable "additional_origin_ips" {
  description = "Extra origin IPs for a multi-cluster load-balancer pool."
  type        = list(string)
  default     = []
}

############################################
# DNS
############################################

variable "dns_records" {
  description = "Map of additional DNS records to create, keyed by a unique name."
  type = map(object({
    name    = string
    type    = string
    content = string
    proxied = optional(bool, true)
    ttl     = optional(number, 1)
    priority = optional(number)
  }))
  default = {
    gitlab = {
      name    = "gitlab"
      type    = "A"
      content = "203.0.113.10"
      proxied = true
    }
    jenkins = {
      name    = "jenkins"
      type    = "A"
      content = "203.0.113.10"
      proxied = true
    }
    argocd = {
      name    = "argocd"
      type    = "A"
      content = "203.0.113.10"
      proxied = true
    }
    grafana = {
      name    = "grafana"
      type    = "A"
      content = "203.0.113.10"
      proxied = true
    }
  }
}

############################################
# SSL/TLS
############################################

variable "ssl_mode" {
  description = "Cloudflare SSL mode: off, flexible, full, strict."
  type        = string
  default     = "strict"
}

variable "min_tls_version" {
  description = "Minimum TLS version accepted at the edge."
  type        = string
  default     = "1.2"
}

variable "always_use_https" {
  description = "Redirect all HTTP requests to HTTPS."
  type        = bool
  default     = true
}

variable "enable_hsts" {
  description = "Enable HSTS (Strict-Transport-Security)."
  type        = bool
  default     = true
}

############################################
# WAF / Firewall
############################################

variable "waf_managed_rules_enabled" {
  description = "Enable the Cloudflare Managed Ruleset + OWASP Core Ruleset."
  type        = bool
  default     = true
}

variable "office_ip_allowlist" {
  description = "CIDR ranges to always allow (e.g. office / VPN egress IPs)."
  type        = list(string)
  default     = ["198.51.100.0/24"]
}

variable "blocked_countries" {
  description = "ISO country codes to block entirely."
  type        = list(string)
  default     = ["RU", "CN", "KP"]
}

variable "block_tor" {
  description = "Block traffic originating from the Tor exit node network."
  type        = bool
  default     = true
}

variable "blocked_asns" {
  description = "ASNs to block (as numbers, without the AS prefix)."
  type        = list(number)
  default     = []
}

############################################
# Cache
############################################

variable "browser_cache_ttl" {
  description = "Browser cache TTL in seconds."
  type        = number
  default     = 14400
}

variable "edge_cache_ttl" {
  description = "Edge cache TTL in seconds for cacheable content."
  type        = number
  default     = 7200
}

variable "cache_everything_paths" {
  description = "URL path patterns to force full caching on (e.g. static assets)."
  type        = list(string)
  default     = ["/static/*", "/assets/*", "/images/*"]
}

############################################
# Rate limiting
############################################

variable "rate_limited_paths" {
  description = "Paths to protect with rate limiting, with threshold and mitigation."
  type = map(object({
    path                = string
    requests_per_period = number
    period_seconds      = number
    mitigation_timeout  = number
  }))
  default = {
    login = {
      path                = "/login"
      requests_per_period = 100
      period_seconds      = 60
      mitigation_timeout  = 600
    }
    api = {
      path                = "/api/*"
      requests_per_period = 300
      period_seconds      = 60
      mitigation_timeout  = 300
    }
    wp_login = {
      path                = "/wp-login.php"
      requests_per_period = 20
      period_seconds       = 60
      mitigation_timeout   = 900
    }
  }
}

############################################
# Load Balancer (Pro+ plan required)
############################################

variable "enable_load_balancer" {
  description = "Create a Cloudflare Load Balancer across multiple origins/clusters."
  type        = bool
  default     = false
}

variable "load_balancer_hostname" {
  description = "Hostname the load balancer answers on, e.g. app.example.com."
  type        = string
  default     = "app"
}

############################################
# Cloudflare Tunnel
############################################

variable "enable_tunnel" {
  description = "Create a Cloudflare Tunnel for private Kubernetes ingress."
  type        = bool
  default     = true
}

variable "tunnel_name" {
  description = "Name for the Cloudflare Tunnel."
  type        = string
  default     = "k8s-tunnel"
}

variable "tunnel_ingress_rules" {
  description = "Hostname -> internal service mappings routed through the tunnel."
  type = map(object({
    hostname = string
    service  = string
  }))
  default = {
    argocd = {
      hostname = "argocd"
      service  = "https://argocd-server.argocd.svc.cluster.local:443"
    }
    grafana = {
      hostname = "grafana"
      service  = "http://grafana.monitoring.svc.cluster.local:80"
    }
  }
}

############################################
# Zero Trust / Access
############################################

variable "enable_zero_trust" {
  description = "Create Zero Trust Access applications and policies."
  type        = bool
  default     = false
}

variable "access_allowed_email_domains" {
  description = "Email domains allowed through Zero Trust Access policies."
  type        = list(string)
  default     = ["example.com"]
}

variable "access_protected_apps" {
  description = "Subdomains to put behind Zero Trust Access."
  type        = list(string)
  default     = ["admin", "vault", "prometheus"]
}

variable "google_oauth_client_id" {
  description = "OAuth client ID for the Google Workspace Zero Trust identity provider."
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_oauth_client_secret" {
  description = "OAuth client secret for the Google Workspace Zero Trust identity provider."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_oauth_client_id" {
  description = "OAuth client ID for the GitHub Zero Trust identity provider."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_oauth_client_secret" {
  description = "OAuth client secret for the GitHub Zero Trust identity provider."
  type        = string
  default     = ""
  sensitive   = true
}

############################################
# Workers
############################################

variable "enable_workers" {
  description = "Deploy a Cloudflare Worker + route."
  type        = bool
  default     = false
}

variable "worker_route_pattern" {
  description = "URL pattern the Worker responds to, e.g. example.com/api/*."
  type        = string
  default     = "example.com/edge/*"
}

############################################
# Pages
############################################

variable "enable_pages" {
  description = "Create a Cloudflare Pages project."
  type        = bool
  default     = false
}

variable "pages_project_name" {
  description = "Name of the Cloudflare Pages project."
  type        = string
  default     = "frontend"
}

variable "pages_production_branch" {
  description = "Git branch deployed to production for the Pages project."
  type        = string
  default     = "main"
}

############################################
# Origin CA
############################################

variable "enable_origin_ca" {
  description = "Issue a Cloudflare Origin CA certificate for the origin server."
  type        = bool
  default     = true
}

variable "origin_ca_hostnames" {
  description = "Hostnames covered by the Origin CA certificate."
  type        = list(string)
  default     = []
}
