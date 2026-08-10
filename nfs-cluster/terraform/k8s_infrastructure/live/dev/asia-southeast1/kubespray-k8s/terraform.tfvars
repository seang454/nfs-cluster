project_id = "project-469c6b81-55a1-4508-830"
region     = "asia-southeast1"
zone       = "asia-southeast1-a"

# Kubespray cluster size.
control_plane_count = 3
worker_count        = 2
nfs_count           = 3

cluster_name         = "kubespray"
instance_name_prefix = "k8s"

# Inventory name prefixes
control_plane_name_prefix = "master"
worker_name_prefix        = "worker"
nfs_name_prefix           = "haproxy"

# Terraform spreads nodes across these zones in order.
zones = [
  "asia-southeast1-a",
  "asia-southeast1-b",
  "asia-southeast1-c"
]

auto_discover_up_zones = true

fallback_regions = [
  "asia-east1",
  "asia-northeast1"
]

blocked_zones   = []
blocked_regions = []

# Recommended: empty means Google automatically discovers ADC for whichever
# user runs Terraform after `gcloud auth application-default login`.
gcp_adc_file = ""

# Machine types are matched by node index.
# e2-medium (1 vCPU, 4GB RAM) allows all 8 nodes (3 master + 2 worker + 3 nfs) to fit within GCP's 12 vCPU global quota (8 vCPUs total).
control_plane_machine_types = [
  "e2-medium"
]

worker_machine_types = [
  "e2-medium"
]

nfs_machine_types = [
  "e2-medium"
]

fallback_machine_types = [
  "e2-medium",
  "e2-standard-2",
  "n2d-standard-2"
]

random_resource_type = [
  "Standard",
  "High CPU",
  "High Memory"
]
# Desired VM power state: "RUNNING" to keep VMs powered on, "TERMINATED" to stop VMs.
desired_status = "RUNNING"

image                           = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
control_plane_boot_disk_size_gb = 50
worker_boot_disk_size_gb        = 50
nfs_boot_disk_size_gb           = 50
nfs_data_disk_size_gb           = 50
boot_disk_type                  = "pd-balanced"

network    = "default"
subnetwork = null

# SSH key Terraform puts on the VM metadata.
ssh_user            = "seang"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# SSH/private key values written into the inventories.
ansible_user                 = ""
ansible_ssh_private_key_file = "~/.ssh/id_rsa"
ansible_python_interpreter   = "/usr/bin/python3"
ansible_ssh_extra_args       = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Terraform writes the real VM IPs into Kubespray & Ansible inventories after apply.
kubespray_inventory_path   = "../../../../../ansible_kubespray_k8s/kubespray/inventory/sample/inventory.ini"
ansible_inventory_path     = "../../../../../ansible_kubespray_k8s/inventory.ini"
nfs_inventory_path         = "../../../../../../ansible-nfs-cluster-genesha/inventory/hosts.ini"

# For learning, this is open. For real use, restrict SSH/API to your public IP CIDR.
ssh_source_ranges            = ["0.0.0.0/0"]
kubernetes_api_source_ranges = ["0.0.0.0/0"]

# Internal node-to-node communication. Adjust this to your VPC/subnet CIDR in production.
internal_source_ranges = ["10.0.0.0/8"]

# Leave empty unless you intentionally expose Kubernetes NodePorts publicly.
nodeport_source_ranges = []

# ---------------------------------------------------------------------------
# Custom firewall rules
# ---------------------------------------------------------------------------
# Add entries here to open any extra port on the cluster VMs.
# Each entry creates one GCP firewall rule.
#
# target: "all"           -> applies to every cluster node
#         "control_plane" -> applies to control plane nodes only
#         "worker"        -> applies to worker nodes only
#
# Examples:
#
# custom_firewall_rules = [
#   {
#     name          = "http-https"
#     protocol      = "tcp"
#     ports         = ["80", "443"]
#     source_ranges = ["0.0.0.0/0"]
#     target        = "all"
#   },
#   {
#     name          = "prometheus-node-exporter"
#     protocol      = "tcp"
#     ports         = ["9100"]
#     source_ranges = ["10.0.0.0/8"]
#     target        = "all"
#   },
#   {
#     name          = "etcd"
#     protocol      = "tcp"
#     ports         = ["2379", "2380"]
#     source_ranges = ["10.0.0.0/8"]
#     target        = "control_plane"
#   },
# ]
custom_firewall_rules = []
