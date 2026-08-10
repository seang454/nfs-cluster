output "instance_name" {
  description = "First GCP VM instance name."
  value       = google_compute_instance.this[0].name
}

output "instance_names" {
  description = "All GCP VM instance names."
  value       = [for instance in google_compute_instance.this : instance.name]
}

output "machine_plan" {
  description = "Terraform-computed machine plan before resource creation."
  value       = local.machines
}

output "usable_zones" {
  description = "Final zones Terraform can use after discovery and blocked filters."
  value       = local.usable_zones
}

output "discovery_regions" {
  description = "Regions Terraform queries for UP zones."
  value       = local.discovery_regions
}

output "discovered_up_zones" {
  description = "Zones returned by GCP with status UP from configured and fallback regions."
  value       = local.discovered_up_zones
}

output "candidate_zones" {
  description = "Preferred UP zones followed by fallback UP zones before blocked filters are applied."
  value       = local.candidate_zones
}

output "static_ips" {
  description = "Reserved static public IP addresses."
  value       = [for address in google_compute_address.this : address.address]
}

output "server_ip" {
  description = "First public IP address for Ansible inventory."
  value       = google_compute_address.this[0].address
}

output "server_ips" {
  description = "All public IP addresses for Ansible inventory."
  value       = [for address in google_compute_address.this : address.address]
}

output "ssh_user" {
  description = "SSH user configured for the VM."
  value       = var.ssh_user
}

output "http_url" {
  description = "First VM public HTTP URL. Nginx routes requests by hostname after Ansible configures the services."
  value       = "http://${google_compute_address.this[0].address}"
}

output "http_urls" {
  description = "Public HTTP URLs for all VMs."
  value       = [for address in google_compute_address.this : "http://${address.address}"]
}

output "https_url" {
  description = "First VM public HTTPS URL. Use a configured service domain for valid TLS."
  value       = "https://${google_compute_address.this[0].address}"
}

output "https_urls" {
  description = "Public HTTPS URLs for all VMs. Use configured service domains for valid TLS."
  value       = [for address in google_compute_address.this : "https://${address.address}"]
}

output "instances" {
  description = "VM details keyed by instance name."
  value = {
    for index, instance in google_compute_instance.this : instance.name => {
      zone         = instance.zone
      machine_type = instance.machine_type
      static_ip    = google_compute_address.this[index].address
      public_ip    = google_compute_address.this[index].address
      http_url     = "http://${google_compute_address.this[index].address}"
      https_url    = "https://${google_compute_address.this[index].address}"
    }
  }
}

output "blocked_zones" {
  description = "Zones currently skipped by Terraform."
  value       = var.blocked_zones
}

output "blocked_regions" {
  description = "Regions currently skipped by Terraform."
  value       = var.blocked_regions
}
