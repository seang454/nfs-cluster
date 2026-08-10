output "tunnel_id" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
  description = "Tunnel ID."
}

output "tunnel_token" {
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
  description = "Token for `cloudflared tunnel run --token <this>` inside the cluster."
}
