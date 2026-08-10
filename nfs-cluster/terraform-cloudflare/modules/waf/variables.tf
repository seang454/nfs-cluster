variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "name" {
  description = "Name for the managed ruleset (useful when applying this module per-subdomain/zone)."
  type        = string
  default     = "Managed WAF"
}

variable "enable_owasp" {
  description = "Enable the OWASP Core Ruleset in addition to the Cloudflare Managed Ruleset."
  type        = bool
  default     = true
}
