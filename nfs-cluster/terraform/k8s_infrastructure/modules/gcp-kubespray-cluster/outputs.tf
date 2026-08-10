output "control_plane_nodes" {
  description = "Kubespray control plane node details."
  value = [
    for node in local.control_plane_nodes : {
      name             = node.name
      instance_name    = node.instance_name
      zone             = node.zone
      machine_type     = node.machine_type
      public_ip        = google_compute_address.this[node.name].address
      private_ip       = google_compute_instance.this[node.name].network_interface[0].network_ip
      etcd_member_name = node.name
    }
  ]
}

output "worker_nodes" {
  description = "Kubespray worker node details."
  value = [
    for node in local.worker_nodes : {
      name          = node.name
      instance_name = node.instance_name
      zone          = node.zone
      machine_type  = node.machine_type
      public_ip     = google_compute_address.this[node.name].address
      private_ip    = google_compute_instance.this[node.name].network_interface[0].network_ip
    }
  ]
}

output "all_nodes" {
  description = "All Kubernetes node details keyed by Kubespray inventory hostname."
  value = {
    for node in local.nodes : node.name => {
      instance_name = node.instance_name
      role          = node.role
      zone          = node.zone
      machine_type  = node.machine_type
      public_ip     = google_compute_address.this[node.name].address
      private_ip    = google_compute_instance.this[node.name].network_interface[0].network_ip
    }
  }
}

output "control_plane_public_ips" {
  description = "Control plane external IP addresses."
  value       = [for node in local.control_plane_nodes : google_compute_address.this[node.name].address]
}

output "worker_public_ips" {
  description = "Worker external IP addresses."
  value       = [for node in local.worker_nodes : google_compute_address.this[node.name].address]
}

output "control_plane_private_ips" {
  description = "Control plane internal IP addresses."
  value       = [for node in local.control_plane_nodes : google_compute_instance.this[node.name].network_interface[0].network_ip]
}

output "worker_private_ips" {
  description = "Worker internal IP addresses."
  value       = [for node in local.worker_nodes : google_compute_instance.this[node.name].network_interface[0].network_ip]
}

output "usable_zones" {
  description = "Final zones Terraform can use after discovery and blocked filters."
  value       = local.usable_zones
}

output "machine_plan" {
  description = "Terraform-computed Kubernetes node plan before resource creation."
  value       = local.nodes
}

output "ssh_user" {
  description = "SSH user configured on all nodes."
  value       = var.ssh_user
}
