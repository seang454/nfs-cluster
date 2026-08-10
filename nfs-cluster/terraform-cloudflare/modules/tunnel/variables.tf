variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID where DNS CNAMEs for the tunnel are created."
  type        = string
}

variable "tunnel_name" {
  description = "Name for the Cloudflare Tunnel."
  type        = string
}

variable "domain" {
  description = "Root domain the tunnel hostnames are created under."
  type        = string
}

variable "ingress_rules" {
  description = "Hostname -> internal service mappings routed through the tunnel."
  type = map(object({
    hostname = string
    service  = string
  }))
}
