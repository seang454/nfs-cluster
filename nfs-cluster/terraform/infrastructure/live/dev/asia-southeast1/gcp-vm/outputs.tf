output "instance_names" {
  description = "All GCP VM instance names."
  value       = module.gcp_vm.instance_names
}

output "machine_plan" {
  description = "Terraform-computed machine plan before resource creation."
  value       = module.gcp_vm.machine_plan
}

output "usable_zones" {
  description = "Final zones Terraform can use after discovery and blocked filters."
  value       = module.gcp_vm.usable_zones
}

output "discovery_regions" {
  description = "Regions Terraform queries for UP zones."
  value       = module.gcp_vm.discovery_regions
}

output "discovered_up_zones" {
  description = "Zones returned by GCP with status UP from configured and fallback regions."
  value       = module.gcp_vm.discovered_up_zones
}

output "candidate_zones" {
  description = "Preferred UP zones followed by fallback UP zones before blocked filters are applied."
  value       = module.gcp_vm.candidate_zones
}

output "static_ips" {
  description = "Reserved static public IP addresses."
  value       = module.gcp_vm.static_ips
}

output "server_ip" {
  description = "First public IP address for Ansible inventory."
  value       = module.gcp_vm.server_ip
}

output "server_ips" {
  description = "All public IP addresses for Ansible inventory."
  value       = module.gcp_vm.server_ips
}

output "ssh_user" {
  description = "SSH user for Ansible."
  value       = module.gcp_vm.ssh_user
}

output "http_url" {
  description = "First VM public HTTP URL."
  value       = module.gcp_vm.http_url
}

output "http_urls" {
  description = "Public HTTP URLs for all VMs."
  value       = module.gcp_vm.http_urls
}

output "https_url" {
  description = "First VM public HTTPS URL. Use a configured service domain for valid TLS."
  value       = module.gcp_vm.https_url
}

output "https_urls" {
  description = "Public HTTPS URLs for all VMs. Use configured service domains for valid TLS."
  value       = module.gcp_vm.https_urls
}

output "instances" {
  description = "VM details keyed by instance name."
  value       = module.gcp_vm.instances
}

output "blocked_zones" {
  description = "Zones currently skipped by Terraform."
  value       = module.gcp_vm.blocked_zones
}

output "blocked_regions" {
  description = "Regions currently skipped by Terraform."
  value       = module.gcp_vm.blocked_regions
}

output "ansible_inventory_path" {
  description = "Generated Ansible inventory file path."
  value       = local_file.ansible_inventory.filename
}

output "cloudflare_dns_records" {
  description = "Cloudflare DNS records created by Terraform."
  value       = var.enable_cloudflare_dns ? module.cloudflare_dns[0].records : {}
}

output "cloudflare_hostnames" {
  description = "Cloudflare hostnames created by Terraform."
  value       = var.enable_cloudflare_dns ? module.cloudflare_dns[0].hostnames : []
}

output "ansible_group_vars_domain_files" {
  description = "Generated Ansible group_vars domain files."
  value       = { for group, file in local_file.ansible_group_vars_domains : group => file.filename }
}
