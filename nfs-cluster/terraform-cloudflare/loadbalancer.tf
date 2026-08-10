# Multi-origin / multi-Kubernetes-cluster load balancing with automatic
# failover. Requires a Cloudflare plan that includes Load Balancing.

resource "cloudflare_load_balancer_monitor" "http_health" {
  count          = var.enable_load_balancer ? 1 : 0
  account_id     = var.account_id
  type           = "https"
  path           = "/healthz"
  expected_codes = "200"
  method         = "GET"
  interval       = 60
  timeout        = 5
  retries        = 2
  description    = "HTTPS health check for cluster origins"
}

resource "cloudflare_load_balancer_pool" "clusters" {
  count      = var.enable_load_balancer ? 1 : 0
  account_id = var.account_id
  name       = "k8s-clusters"

  origins = concat(
    [
      {
        name    = "cluster-1"
        address = var.origin_ip
        enabled = true
        weight  = 1
      }
    ],
    [
      for idx, ip in var.additional_origin_ips : {
        name    = "cluster-${idx + 2}"
        address = ip
        enabled = true
        weight  = 1
      }
    ]
  )

  monitor          = var.enable_load_balancer ? cloudflare_load_balancer_monitor.http_health[0].id : null
  minimum_origins  = 1
  notification_email = "ops@${var.domain}"
}

resource "cloudflare_load_balancer" "this" {
  count            = var.enable_load_balancer ? 1 : 0
  zone_id          = var.zone_id
  name             = "${var.load_balancer_hostname}.${var.domain}"
  fallback_pool = cloudflare_load_balancer_pool.clusters[0].id
  default_pools = [cloudflare_load_balancer_pool.clusters[0].id]
  proxied          = true
  steering_policy  = "off" # or "dynamic_latency", "geo", "random"

  session_affinity = "cookie"
}
