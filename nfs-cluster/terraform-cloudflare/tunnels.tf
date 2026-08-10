# Cloudflare Tunnel — gives your Kubernetes ingress a way in without a public
# LoadBalancer IP. Pair this with `cloudflared` running as a Deployment in
# your cluster (Helm chart: community-charts/cloudflared or a raw manifest).

resource "random_password" "tunnel_secret" {
  count   = var.enable_tunnel ? 1 : 0
  length  = 64
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "k8s" {
  count      = var.enable_tunnel ? 1 : 0
  account_id = var.account_id
  name          = var.tunnel_name
  tunnel_secret = base64encode(random_password.tunnel_secret[0].result)
  config_src    = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "k8s" {
  count      = var.enable_tunnel ? 1 : 0
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.k8s[0].id

  config = {
    ingress = concat(
      [
        for key, rule in var.tunnel_ingress_rules : {
          hostname = "${rule.hostname}.${var.domain}"
          service  = rule.service
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}

# DNS CNAME per ingress rule, pointing at <tunnel-id>.cfargotunnel.com
resource "cloudflare_dns_record" "tunnel_cname" {
  for_each = var.enable_tunnel ? var.tunnel_ingress_rules : {}

  zone_id = var.zone_id
  name    = each.value.hostname
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k8s[0].id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

output "tunnel_id" {
  value       = var.enable_tunnel ? cloudflare_zero_trust_tunnel_cloudflared.k8s[0].id : null
  description = "Tunnel ID — use this in the cloudflared Deployment's credentials/config."
}

# (tunnel_token is no longer exported in provider v5.x)
