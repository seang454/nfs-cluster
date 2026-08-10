module "kubespray_cluster" {
  source = "../../../../modules/gcp-kubespray-cluster"

  cluster_name                    = var.cluster_name
  instance_name_prefix            = var.instance_name_prefix
  control_plane_count             = var.control_plane_count
  worker_count                    = var.worker_count
  control_plane_name_prefix       = var.control_plane_name_prefix
  worker_name_prefix              = var.worker_name_prefix
  zone                            = var.zone
  zones                           = var.zones
  auto_discover_up_zones          = var.auto_discover_up_zones
  fallback_regions                = var.fallback_regions
  blocked_zones                   = var.blocked_zones
  blocked_regions                 = var.blocked_regions
  control_plane_machine_types     = var.control_plane_machine_types
  worker_machine_types            = var.worker_machine_types
  fallback_machine_types          = var.fallback_machine_types
  random_resource_type            = var.random_resource_type
  desired_status                  = var.desired_status
  image                           = var.image
  control_plane_boot_disk_size_gb = var.control_plane_boot_disk_size_gb
  worker_boot_disk_size_gb        = var.worker_boot_disk_size_gb
  boot_disk_type                  = var.boot_disk_type
  network                         = var.network
  subnetwork                      = var.subnetwork
  ssh_user                        = var.ssh_user
  ssh_public_key_path             = var.ssh_public_key_path
  ssh_public_key                  = local.ssh_public_key
  ssh_source_ranges               = var.ssh_source_ranges
  internal_source_ranges          = var.internal_source_ranges
  kubernetes_api_source_ranges    = var.kubernetes_api_source_ranges
  nodeport_source_ranges          = var.nodeport_source_ranges
  custom_firewall_rules           = var.custom_firewall_rules

  labels = {
    environment = "dev"
    app         = "kubespray"
    managed_by  = "terraform"
  }
}
