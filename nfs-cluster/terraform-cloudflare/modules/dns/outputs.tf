output "record_ids" {
  value       = { for k, r in cloudflare_dns_record.this : k => r.id }
  description = "Map of record key to Cloudflare DNS record ID."
}

output "hostnames" {
  value       = { for k, r in cloudflare_dns_record.this : k => r.hostname }
  description = "Map of record key to fully-qualified hostname."
}
