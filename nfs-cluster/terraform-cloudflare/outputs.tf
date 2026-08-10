output "zone_id" {
  value       = var.zone_id
  description = "Cloudflare zone ID in use."
}

output "domain" {
  value       = var.domain
  description = "Root domain managed by this project."
}

output "dns_record_names" {
  value       = [for r in cloudflare_dns_record.additional : r.name]
  description = "Names of the additional DNS records created from var.dns_records."
}

output "load_balancer_hostname" {
  value       = var.enable_load_balancer ? cloudflare_load_balancer.this[0].name : null
  description = "Hostname the Cloudflare Load Balancer answers on, if enabled."
}

output "pages_subdomain" {
  value       = var.enable_pages ? cloudflare_pages_project.frontend[0].subdomain : null
  description = "Default *.pages.dev subdomain for the Pages project, if enabled."
}

output "worker_route" {
  value       = var.enable_workers ? cloudflare_workers_route.edge[0].pattern : null
  description = "URL pattern the deployed Worker responds to, if enabled."
}
