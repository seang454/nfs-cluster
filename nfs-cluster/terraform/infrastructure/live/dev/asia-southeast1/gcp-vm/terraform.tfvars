project_id = "project-ef47043f-b178-4cb8-992"
region     = "asia-southeast1"
zone       = "asia-southeast1-a"
# Number of VMs to create. Use 2 because DNS records use vm_index = 2.
instance_count = 2

# Terraform spreads VMs across these zones in order.
zones = [
  "asia-southeast1-a",
  "asia-southeast1-b",
  "asia-southeast1-c"
]

# Dynamic zone discovery asks GCP for zones with status UP before creating the VM plan.
auto_discover_up_zones = true

# Terraform can use these regions if preferred zones are down or blocked.
fallback_regions = [
  "asia-east1",
  "asia-northeast1"
]

# If GCP returns ZONE_RESOURCE_POOL_EXHAUSTED or a zone is down,
# add the bad zone or region here and rerun terraform apply.
# To remap to another region, also add zones from that other region to zones above.
blocked_zones   = []
blocked_regions = []

# Recommended: empty means Google automatically discovers ADC for whichever
# user runs Terraform after `gcloud auth application-default login`.
gcp_adc_file = "/home/seang/.config/gcloud/application_default_credentials.json"

# Optional explicit Linux/WSL path. "~" dynamically means the current user:
# gcp_adc_file = "~/.config/gcloud/application_default_credentials.json"

# GCP VM names cannot use underscores. Terraform creates gcp-vm-1, gcp-vm-2, ...
name = "gcp-vm"

# Machine types are matched by VM index.
# 1 value  = all VMs use this type.
# 2 values = VM 1 uses value 1, VM 2 and later use value 2.
# 3 values = VM 1 uses value 1, VM 2 uses value 2, VM 3 and later use value 3.
machine_types = [
  "e2-standard-2"
]

# RUNNING keeps Terraform-managed VMs up. TERMINATED stops them.
desired_status = "RUNNING"

network    = "default"
subnetwork = null

ssh_user            = "seang"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# Terraform writes the VM external IPs into this Ansible inventory after apply.
ansible_inventory_path       = "../../../../../ansible_service_config/inventories/dev/hosts.ini"
ansible_inventory_groups     = ["defectdojo", "harbor", "jenkins", "nexus", "sonarqube", "trivy", "vault"]
ansible_ssh_private_key_path = "~/.ssh/id_rsa"

# Explicit service-to-VM map. This keeps inventory correct even while
# Cloudflare DNS is disabled.
ansible_service_targets = {
  defectdojo = { vm_index = 2 }
  harbor     = { vm_index = 2 }
  jenkins    = { vm_index = 1 }
  nexus      = { vm_index = 2 }
  sonarqube  = { vm_index = 1 }
  trivy      = { vm_index = 2 }
  vault      = { vm_index = 2 }
}

enable_ansible_group_vars_domains = true
ansible_group_vars_path           = "../../../../../ansible_service_config/group_vars"

# Cloudflare DNS is disabled until you set your real zone ID and token.
# Prefer setting CLOUDFLARE_API_TOKEN in your shell instead of putting a token here.
enable_cloudflare_dns = true
cloudflare_zone_id    = "25794f1056c9f59652052d977bd73acb"
cloudflare_api_token  = ""

# vm_index is one-based:
# vm_index = 1 uses gcp-vm-1 external IP.
# vm_index = 2 uses gcp-vm-2 external IP.
# If you enable Cloudflare DNS with vm_index = 2, set instance_count = 2.
cloudflare_dns_records = {
  defectdojo = {
    hostname = "defectdojo.seang.shop"
    type     = "A"
    vm_index = 2
    proxied  = false
  }

  harbor = {
    hostname = "harbor.seang.shop"
    type     = "A"
    vm_index = 2
    proxied  = false
  }

  jenkins = {
    hostname = "jenkins.seang.shop"
    type     = "A"
    vm_index = 1
    proxied  = false
  }

  sonarqube = {
    hostname = "sonarqube.seang.shop"
    type     = "A"
    vm_index = 1
    proxied  = false
  }

  nexus = {
    hostname = "nexus.seang.shop"
    type     = "A"
    vm_index = 2
    proxied  = false
  }

  nexus_docker = {
    hostname             = "docker.seang.shop"
    type                 = "A"
    vm_index             = 2
    proxied              = false
    create_ansible_group = false
  }

  vault = {
    hostname = "vault.seang.shop"
    type     = "A"
    vm_index = 2
    proxied  = false
  }

  trivy = {
    hostname = "trivy.seang.shop"
    type     = "A"
    vm_index = 2
    proxied  = false
  }

  defectdojo_alias = {
    hostname = "dojo.seang.shop"
    type     = "CNAME"
    content  = "defectdojo.seang.shop"
    proxied  = false
  }

  jenkins_alias = {
    hostname = "ci.seang.shop"
    type     = "CNAME"
    content  = "jenkins.seang.shop"
    proxied  = false
  }

  nexus_alias = {
    hostname = "repo.seang.shop"
    type     = "CNAME"
    content  = "nexus.seang.shop"
    proxied  = false
  }

  nexus_docker_alias = {
    hostname = "registry.seang.shop"
    type     = "CNAME"
    content  = "docker.seang.shop"
    proxied  = false
  }

  sonarqube_alias = {
    hostname = "quality.seang.shop"
    type     = "CNAME"
    content  = "sonarqube.seang.shop"
    proxied  = false
  }

  trivy_alias = {
    hostname = "scanner.seang.shop"
    type     = "CNAME"
    content  = "trivy.seang.shop"
    proxied  = false
  }

  vault_alias = {
    hostname = "secrets.seang.shop"
    type     = "CNAME"
    content  = "vault.seang.shop"
    proxied  = false
  }
}

# GCP firewall ports used by the Ansible service roles:
# - 22: SSH for Ansible. Restrict this to your public IP for real use.
# - 80: Nginx HTTP and Certbot validation.
# - 443: Nginx HTTPS for every service domain.
#
# Backend ports such as SonarQube 9000, Jenkins 8080, Nexus 8081/8082,
# Trivy 4954, and Vault 8200 stay behind Nginx and are not opened by GCP.
ssh_source_ranges            = ["0.0.0.0/0"]
public_service_ports         = [80, 443]
public_service_source_ranges = ["0.0.0.0/0"]

# Service backend ports (typically behind Nginx, but now exposed for direct access if needed):
# - Jenkins: 8080
# - SonarQube: 9000
# - Nexus UI: 8081
# - Nexus Docker repo: 8082
# - DefectDojo: 8000
# - Trivy: 4954
# - Vault: 8200
additional_service_ports         = [8000, 8080, 8081, 8082, 8200, 4954, 9000]
additional_service_source_ranges = ["0.0.0.0/0"]
