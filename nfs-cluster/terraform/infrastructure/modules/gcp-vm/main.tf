locals {
  network_tag = "${var.name}-services"

  # If zones is empty, use the single fallback zone.
  # If zones has values, Terraform will spread VMs across that zone list.
  configured_zones = length(var.zones) > 0 ? var.zones : [var.zone]

  # Regions are derived from zone names like asia-southeast1-a -> asia-southeast1.
  # fallback_regions lets Terraform look outside the preferred region if needed.
  configured_regions = distinct([for zone in local.configured_zones : replace(zone, "/-[a-z]$/", "")])
  discovery_regions  = distinct(concat(local.configured_regions, var.fallback_regions))
  ssh_public_key     = trimspace(var.ssh_public_key) != "" ? trimspace(var.ssh_public_key) : trimspace(file(pathexpand(var.ssh_public_key_path)))
}

data "google_compute_zones" "available" {
  for_each = var.auto_discover_up_zones ? toset(local.discovery_regions) : toset([])

  region = each.value
  status = "UP"
}

locals {
  discovered_up_zones = flatten([
    for region in local.discovery_regions : try(data.google_compute_zones.available[region].names, [])
  ])

  # Keep your preferred zones first, but only when GCP says they are UP.
  preferred_up_zones = var.auto_discover_up_zones ? [
    for zone in local.configured_zones : zone
    if contains(local.discovered_up_zones, zone)
  ] : local.configured_zones

  # Then add other UP zones from the same regions or fallback regions.
  fallback_up_zones = var.auto_discover_up_zones ? [
    for zone in local.discovered_up_zones : zone
    if !contains(local.configured_zones, zone)
  ] : []

  candidate_zones = concat(local.preferred_up_zones, local.fallback_up_zones)

  # Terraform cannot catch a GCP create error and retry another zone in the same apply.
  # Instead, add failed zones or regions to blocked_zones/blocked_regions, then rerun apply.
  usable_zones = [
    for zone in local.candidate_zones : zone
    if !contains(var.blocked_zones, zone) && !contains(var.blocked_regions, replace(zone, "/-[a-z]$/", ""))
  ]

  # This fallback prevents index errors before the preflight check prints a clear message.
  effective_zones = length(local.usable_zones) > 0 ? local.usable_zones : ["no-usable-zone"]

  # Terraform version of the Ansible machines_info list.
  machines = [
    for index in range(var.instance_count) : {
      name              = format("%s-%d", var.name, index + 1)
      zone              = local.effective_zones[index % length(local.effective_zones)]
      region            = replace(local.effective_zones[index % length(local.effective_zones)], "/-[a-z]$/", "")
      machine_type      = var.machine_types[min(index, length(var.machine_types) - 1)]
      desired_status    = var.desired_status
      image             = var.image
      boot_disk_size_gb = var.boot_disk_size_gb
      boot_disk_type    = var.boot_disk_type
    }
  ]
}

resource "terraform_data" "preflight" {
  input = {
    configured_zones = local.configured_zones
    usable_zones     = local.usable_zones
    blocked_zones    = var.blocked_zones
    blocked_regions  = var.blocked_regions
  }

  lifecycle {
    precondition {
      condition     = length(local.usable_zones) > 0
      error_message = "No usable GCP zones remain. Remove values from blocked_zones/blocked_regions or add more zones."
    }

    precondition {
      condition     = length(var.additional_service_ports) == 0 || length(var.additional_service_source_ranges) > 0
      error_message = "Set additional_service_source_ranges when additional_service_ports contains ports."
    }
  }
}

# Terraform resource block format:
# resource "PROVIDER_RESOURCE_TYPE" "LOCAL_NAME" {}
#
# google_compute_address = resource type from the Google provider.
# this                   = local Terraform name we choose and use in references.
#
# Example reference:
# google_compute_address.this[count.index].address
resource "google_compute_address" "this" {
  count = var.instance_count

  name   = "${local.machines[count.index].name}-ip"
  region = local.machines[count.index].region

  depends_on = [terraform_data.preflight]
}

resource "google_compute_instance" "this" {
  # count is a Terraform meta-argument.
  # It works like a loop for resources:
  # instance_count = 1 creates 1 VM
  # instance_count = 3 creates 3 VMs
  count = var.instance_count

  # count.index starts at 0, so we add 1 to create human-friendly names:
  # gcp-vm-1, gcp-vm-2, gcp-vm-3
  name = local.machines[count.index].name

  # machine_types follows the VM index:
  # VM 1 uses machine_types[0]
  # VM 2 uses machine_types[1]
  # If there are more VMs than machine_types values, Terraform reuses the last value.
  # Example: 3 VMs + 2 machine types = VM 1 uses type 1, VM 2 and VM 3 use type 2.
  machine_type = local.machines[count.index].machine_type

  # Allows Terraform to stop/start the VM when an update requires it.
  desired_status            = local.machines[count.index].desired_status
  allow_stopping_for_update = true

  # The modulo operator (%) rotates through the zone list.
  # Example with 4 VMs and 3 zones:
  # VM 1 -> zone 1, VM 2 -> zone 2, VM 3 -> zone 3, VM 4 -> zone 1 again.
  zone = local.machines[count.index].zone
  tags = distinct(concat(var.network_tags, [local.network_tag]))

  boot_disk {
    initialize_params {
      image = local.machines[count.index].image
      size  = local.machines[count.index].boot_disk_size_gb
      type  = local.machines[count.index].boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      # Static public IP reserved by Terraform before VM creation.
      nat_ip = google_compute_address.this[count.index].address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }

  labels = var.labels
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.name}-allow-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = [local.network_tag]
}

# Optional direct-access ports that cannot use the Nginx HTTP/HTTPS path.
# Keep source ranges restricted because this rule targets every service VM.
resource "google_compute_firewall" "additional_services" {
  count = length(var.additional_service_ports) > 0 ? 1 : 0

  name    = "${var.name}-allow-additional-services"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [for port in var.additional_service_ports : tostring(port)]
  }

  source_ranges = var.additional_service_source_ranges
  target_tags   = [local.network_tag]
}

# Every current Ansible service role publishes its user-facing endpoint through
# Nginx. GCP only needs to admit HTTP/HTTPS; localhost backend traffic never
# crosses the GCP firewall.
resource "google_compute_firewall" "public_services" {
  name    = "${var.name}-allow-public-services"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [for port in var.public_service_ports : tostring(port)]
  }

  source_ranges = var.public_service_source_ranges
  target_tags   = [local.network_tag]
}
