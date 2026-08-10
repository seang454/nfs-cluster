variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_adc_file" {
  description = "Optional ADC JSON path. Leave empty for automatic per-user ADC discovery, or use ~ for the current user's home directory."
  type        = string
  default     = ""
  sensitive   = true
}

variable "region" {
  description = "GCP region."
  type        = string
  default     = "asia-southeast1"
}

variable "cluster_name" {
  description = "Short cluster name used in labels and firewall names."
  type        = string
  default     = "kubespray"
}

variable "instance_name_prefix" {
  description = "Prefix used for GCP VM instance names."
  type        = string
  default     = "k8s"
}

variable "control_plane_count" {
  description = "Number of Kubernetes control plane nodes."
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of Kubernetes worker nodes."
  type        = number
  default     = 2
}

variable "nfs_count" {
  description = "Number of NFS storage nodes."
  type        = number
  default     = 3
}

variable "control_plane_name_prefix" {
  description = "Kubespray inventory hostname prefix for control plane nodes."
  type        = string
  default     = "master"
}

variable "worker_name_prefix" {
  description = "Kubespray inventory hostname prefix for worker nodes."
  type        = string
  default     = "worker"
}

variable "nfs_name_prefix" {
  description = "Inventory hostname prefix for NFS storage nodes."
  type        = string
  default     = "haproxy"
}

variable "nfs_machine_types" {
  description = "Machine types for NFS storage nodes."
  type        = list(string)
  default     = ["e2-standard-2"]
}

variable "nfs_boot_disk_size_gb" {
  description = "NFS node boot disk size in GB."
  type        = number
  default     = 50
}

variable "nfs_data_disk_size_gb" {
  description = "NFS node data disk size in GB for Ceph OSD."
  type        = number
  default     = 50
}

variable "nfs_inventory_path" {
  description = "Relative path where the generated NFS cluster inventory file is written."
  type        = string
  default     = "../../../../../ansible-nfs-cluster-genesha/inventory/hosts.ini"
}

variable "zone" {
  description = "Fallback GCP zone used when zones is empty."
  type        = string
  default     = "asia-southeast1-a"
}

variable "zones" {
  description = "List of GCP zones used to spread Kubernetes nodes. If empty, Terraform uses zone."
  type        = list(string)
  default     = []
}

variable "auto_discover_up_zones" {
  description = "When true, Terraform asks GCP for zones with status UP before building the node plan."
  type        = bool
  default     = true
}

variable "fallback_regions" {
  description = "Extra GCP regions Terraform may use when preferred zones are down or blocked."
  type        = list(string)
  default     = []
}

variable "blocked_zones" {
  description = "GCP zones to skip after a zone is down or exhausted."
  type        = list(string)
  default     = []
}

variable "blocked_regions" {
  description = "GCP regions to skip after a resource pool is exhausted."
  type        = list(string)
  default     = []
}

variable "control_plane_machine_types" {
  description = "Machine types for control plane nodes by index. If there are more nodes than values, Terraform reuses the last value."
  type        = list(string)
  default     = ["e2-standard-2"]
}

variable "worker_machine_types" {
  description = "Machine types for worker nodes by index. If there are more nodes than values, Terraform reuses the last value."
  type        = list(string)
  default     = ["e2-standard-2"]
}

variable "fallback_machine_types" {
  description = "Fallback machine types to try if primary machine type is unavailable."
  type        = list(string)
  default     = ["n2-standard-2", "n1-standard-2", "e2-standard-4", "e2-highcpu-2", "e2-highmem-2"]
}

variable "random_resource_type" {
  description = "Allowed resource families (Standard, High CPU, High Memory) when selecting machine types."
  type        = list(string)
  default     = ["Standard", "High CPU", "High Memory"]
}

variable "desired_status" {
  description = "Desired VM power state. RUNNING keeps Terraform-managed VMs up; TERMINATED stops them."
  type        = string
  default     = "RUNNING"

  validation {
    condition     = contains(["RUNNING", "TERMINATED"], var.desired_status)
    error_message = "desired_status must be RUNNING or TERMINATED."
  }
}

variable "image" {
  description = "Boot disk image."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "control_plane_boot_disk_size_gb" {
  description = "Control plane boot disk size in GB."
  type        = number
  default     = 50
}

variable "worker_boot_disk_size_gb" {
  description = "Worker boot disk size in GB."
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "GCP VPC network name or self link."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "GCP subnetwork name or self link. Leave null to use default behavior."
  type        = string
  default     = null
}

variable "ssh_user" {
  description = "Linux SSH username configured on the GCP VMs."
  type        = string
  default     = "seang"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key Terraform adds to each VM. If this file and ansible_ssh_private_key_file do not exist, Terraform generates them. A leading ~ uses the current Terraform user's home directory."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to connect to SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "internal_source_ranges" {
  description = "CIDR ranges allowed for internal Kubernetes node-to-node traffic."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "kubernetes_api_source_ranges" {
  description = "CIDR ranges allowed to connect to the Kubernetes API server on 6443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nodeport_source_ranges" {
  description = "Optional CIDR ranges allowed to connect to NodePort range 30000-32767. Leave empty to skip this firewall rule."
  type        = list(string)
  default     = []
}

variable "kubespray_inventory_path" {
  description = "Path where Terraform writes the generated Kubespray inventory file (used by Kubespray cluster.yml)."
  type        = string
  default     = "../../../../../ansible_kubespray_k8s/kubespray/inventory/sample/inventory.ini"
}

variable "ansible_inventory_path" {
  description = "Path where Terraform writes the generated Ansible inventory for ansible_kubespray_k8s playbooks (zsh setup, pre-flight checks, etc.)."
  type        = string
  default     = "../../../../../ansible_kubespray_k8s/inventory.ini"
}

variable "ansible_user" {
  description = "Optional Ansible SSH user written into the Kubespray inventory. Leave empty to reuse ssh_user."
  type        = string
  default     = ""
}

variable "ansible_ssh_private_key_file" {
  description = "SSH private key path written into the Kubespray inventory. If this file and ssh_public_key_path do not exist, Terraform generates them. A leading ~ uses the current Terraform user's home directory."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ansible_python_interpreter" {
  description = "Python interpreter path written into the Kubespray inventory."
  type        = string
  default     = "/usr/bin/python3"
}

variable "ansible_ssh_extra_args" {
  description = "Extra SSH options written into the Kubespray inventory."
  type        = string
  default     = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
}

# ---------------------------------------------------------------------------
# Custom firewall rules
# ---------------------------------------------------------------------------
# Opens arbitrary ports on cluster VMs beyond the built-in SSH / API / internal
# rules. Each entry creates one GCP firewall rule.
#
# target values: "all" (every node), "control_plane", or "worker"
variable "custom_firewall_rules" {
  description = "List of custom firewall rules to add to the cluster. Each rule opens one or more ports for a given protocol and set of source CIDR ranges. Set target to 'all', 'control_plane', or 'worker' to scope the rule."
  type = list(object({
    name          = string
    protocol      = string
    ports         = list(string)
    source_ranges = list(string)
    target        = optional(string, "all")
  }))
  default = []
}
