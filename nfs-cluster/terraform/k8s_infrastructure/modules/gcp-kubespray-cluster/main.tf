locals {
  cluster_tag       = "${var.instance_name_prefix}-cluster"
  control_plane_tag = "${var.instance_name_prefix}-control-plane"
  worker_tag        = "${var.instance_name_prefix}-worker"

  configured_zones   = length(var.zones) > 0 ? var.zones : [var.zone]
  configured_regions = distinct([for zone in local.configured_zones : replace(zone, "/-[a-z]$/", "")])
  discovery_regions  = distinct(concat(local.configured_regions, var.fallback_regions))
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

  preferred_up_zones = var.auto_discover_up_zones ? [
    for zone in local.configured_zones : zone
    if contains(local.discovered_up_zones, zone)
  ] : local.configured_zones

  fallback_up_zones = var.auto_discover_up_zones ? [
    for zone in local.discovered_up_zones : zone
    if !contains(local.configured_zones, zone)
  ] : []

  candidate_zones = concat(local.preferred_up_zones, local.fallback_up_zones)

  usable_zones = [
    for zone in local.candidate_zones : zone
    if !contains(var.blocked_zones, zone) && !contains(var.blocked_regions, replace(zone, "/-[a-z]$/", ""))
  ]

  effective_zones = length(local.usable_zones) > 0 ? local.usable_zones : ["no-usable-zone"]

  fallback_machine_candidates = distinct(compact(concat(
    var.fallback_machine_types,
    contains(var.random_resource_type, "Standard") ? ["n2d-standard-2", "n1-standard-2", "e2-standard-4"] : [],
    contains(var.random_resource_type, "High CPU") ? ["e2-highcpu-2", "n2-highcpu-2"] : [],
    contains(var.random_resource_type, "High Memory") ? ["e2-highmem-2", "n2-highmem-2"] : []
  )))

  control_plane_nodes = [
    for index in range(var.control_plane_count) : {
      name              = format("%s%02d", var.control_plane_name_prefix, index + 1)
      instance_name     = format("%s-%s%02d", var.instance_name_prefix, var.control_plane_name_prefix, index + 1)
      role              = "control_plane"
      node_index        = index
      global_index      = index
      zone              = local.effective_zones[index % length(local.effective_zones)]
      region            = replace(local.effective_zones[index % length(local.effective_zones)], "/-[a-z]$/", "")
      machine_type      = var.control_plane_machine_types[min(index, length(var.control_plane_machine_types) - 1)]
      boot_disk_size_gb = var.control_plane_boot_disk_size_gb
    }
  ]

  worker_nodes = [
    for index in range(var.worker_count) : {
      name              = format("%s%02d", var.worker_name_prefix, index + 1)
      instance_name     = format("%s-%s%02d", var.instance_name_prefix, var.worker_name_prefix, index + 1)
      role              = "worker"
      node_index        = index
      global_index      = var.control_plane_count + index
      zone              = local.effective_zones[(var.control_plane_count + index) % length(local.effective_zones)]
      region            = replace(local.effective_zones[(var.control_plane_count + index) % length(local.effective_zones)], "/-[a-z]$/", "")
      machine_type      = var.worker_machine_types[min(index, length(var.worker_machine_types) - 1)]
      boot_disk_size_gb = var.worker_boot_disk_size_gb
    }
  ]

  nodes         = concat(local.control_plane_nodes, local.worker_nodes)
  nodes_by_name = { for node in local.nodes : node.name => node }

  ssh_public_key = trimspace(var.ssh_public_key) != "" ? trimspace(var.ssh_public_key) : trimspace(file(pathexpand(var.ssh_public_key_path)))
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
  }
}

resource "google_compute_address" "this" {
  for_each = local.nodes_by_name

  name   = "${each.value.instance_name}-ip"
  region = each.value.region

  depends_on = [terraform_data.preflight]
}

resource "google_compute_instance" "this" {
  for_each = local.nodes_by_name

  name                      = each.value.instance_name
  machine_type              = each.value.machine_type
  desired_status            = var.desired_status
  allow_stopping_for_update = true
  zone                      = each.value.zone

  tags = distinct(concat(
    var.network_tags,
    [
      local.cluster_tag,
      each.value.role == "control_plane" ? local.control_plane_tag : local.worker_tag,
    ]
  ))

  boot_disk {
    initialize_params {
      image = var.image
      size  = each.value.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      nat_ip = google_compute_address.this[each.key].address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }

  labels = merge(var.labels, {
    cluster = var.cluster_name
    role    = each.value.role
  })
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.instance_name_prefix}-allow-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = [local.cluster_tag]
}

resource "google_compute_firewall" "internal" {
  name    = "${var.instance_name_prefix}-allow-internal"
  network = var.network

  allow {
    protocol = "all"
  }

  source_ranges = var.internal_source_ranges
  target_tags   = [local.cluster_tag]
}

resource "google_compute_firewall" "kubernetes_api" {
  name    = "${var.instance_name_prefix}-allow-kube-api"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = var.kubernetes_api_source_ranges
  target_tags   = [local.control_plane_tag]
}

resource "google_compute_firewall" "nodeport" {
  count = length(var.nodeport_source_ranges) > 0 ? 1 : 0

  name    = "${var.instance_name_prefix}-allow-nodeport"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = var.nodeport_source_ranges
  target_tags   = [local.cluster_tag]
}

# ---------------------------------------------------------------------------
# Custom firewall rules (from var.custom_firewall_rules)
# ---------------------------------------------------------------------------
resource "google_compute_firewall" "custom" {
  for_each = {
    for rule in var.custom_firewall_rules :
    rule.name => rule
  }

  name    = "${var.instance_name_prefix}-custom-${each.key}"
  network = var.network

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  source_ranges = each.value.source_ranges

  target_tags = (
    coalesce(each.value.target, "all") == "control_plane" ? [local.control_plane_tag] :
    coalesce(each.value.target, "all") == "worker" ? [local.worker_tag] :
    [local.cluster_tag]
  )
}
