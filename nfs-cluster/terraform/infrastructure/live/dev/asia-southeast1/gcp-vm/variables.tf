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

variable "zone" {
  description = "Fallback GCP zone used when zones is empty."
  type        = string
  default     = "asia-southeast1-a"
}

variable "instance_count" {
  description = "Number of VM instances to create."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && floor(var.instance_count) == var.instance_count
    error_message = "instance_count must be a whole number that is 1 or greater."
  }
}

variable "zones" {
  description = "List of GCP zones used to spread VMs. If empty, Terraform uses zone."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.zones) == 0 || alltrue([for zone in var.zones : trimspace(zone) != ""])
    error_message = "zones cannot contain empty strings."
  }
}

variable "auto_discover_up_zones" {
  description = "When true, Terraform asks GCP for zones with status UP before building the VM plan."
  type        = bool
  default     = true
}

variable "fallback_regions" {
  description = "Extra GCP regions Terraform may use when preferred zones are down or blocked."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for region in var.fallback_regions : trimspace(region) != ""])
    error_message = "fallback_regions cannot contain empty strings."
  }
}

variable "blocked_zones" {
  description = "GCP zones to skip after a zone is down or exhausted, for example asia-southeast1-a."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for zone in var.blocked_zones : trimspace(zone) != ""])
    error_message = "blocked_zones cannot contain empty strings."
  }
}

variable "blocked_regions" {
  description = "GCP regions to skip after a resource pool is exhausted, for example asia-southeast1."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for region in var.blocked_regions : trimspace(region) != ""])
    error_message = "blocked_regions cannot contain empty strings."
  }
}

variable "name" {
  description = "Base VM instance name. Terraform appends -1, -2, and so on. Use hyphens, not underscores."
  type        = string
  default     = "gcp-vm"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "name must be a valid GCP VM name prefix: lowercase letters, numbers, and hyphens only. It must start with a letter and cannot end with a hyphen."
  }
}

variable "machine_types" {
  description = "Machine types by VM index. If there are more VMs than values, Terraform reuses the last value."
  type        = list(string)
  default     = ["e2-standard-2"]

  validation {
    condition     = length(var.machine_types) > 0 && alltrue([for machine_type in var.machine_types : trimspace(machine_type) != ""])
    error_message = "machine_types must contain at least one non-empty machine type."
  }
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

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
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
  description = "Linux SSH username."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key. If this file and ansible_ssh_private_key_path do not exist, Terraform generates them. A leading ~ uses the current Terraform user's home directory."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to connect to SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "public_service_ports" {
  description = "Public TCP ports exposed through the GCP firewall. The Ansible service roles use Nginx on ports 80 and 443."
  type        = list(number)
  default     = [80, 443]

  validation {
    condition     = length(var.public_service_ports) > 0 && alltrue([for port in var.public_service_ports : port >= 1 && port <= 65535 && floor(port) == port])
    error_message = "public_service_ports must contain valid TCP port numbers from 1 through 65535."
  }
}

variable "public_service_source_ranges" {
  description = "CIDR ranges allowed to access public service ports."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_service_ports" {
  description = "Optional TCP ports that bypass Nginx, such as Jenkins inbound-agent port 50000."
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for port in var.additional_service_ports : port >= 1 && port <= 65535 && floor(port) == port])
    error_message = "additional_service_ports must contain valid TCP port numbers from 1 through 65535."
  }
}

variable "additional_service_source_ranges" {
  description = "Restricted CIDR ranges allowed to access additional service ports."
  type        = list(string)
  default     = []
}

variable "ansible_inventory_path" {
  description = "Path where Terraform writes the generated Ansible inventory file."
  type        = string
  default     = "../../../../../ansible_service_config/inventories/dev/hosts.ini"
}

variable "ansible_inventory_groups" {
  description = "Fallback Ansible inventory groups that receive all Terraform-created VMs when no dynamic service targets are available."
  type        = list(string)
  default     = ["sonarqube"]

  validation {
    condition     = length(var.ansible_inventory_groups) > 0 && alltrue([for group in var.ansible_inventory_groups : can(regex("^[A-Za-z0-9_-]+$", group))])
    error_message = "ansible_inventory_groups must contain at least one valid Ansible group name."
  }
}

variable "ansible_service_targets" {
  description = "Optional explicit Ansible service groups mapped to one VM index. If empty, Terraform can derive groups from Cloudflare A/AAAA records when Cloudflare DNS is enabled."
  type = map(object({
    vm_index = number
  }))
  default = {}

  validation {
    condition = alltrue([
      for group, target in var.ansible_service_targets :
      can(regex("^[A-Za-z0-9_-]+$", group)) && target.vm_index >= 1
    ])
    error_message = "ansible_service_targets keys must be valid Ansible group names and vm_index must be 1 or greater."
  }
}

variable "ansible_ssh_private_key_path" {
  description = "SSH private key path Ansible should use to connect to the Terraform-created VMs. If this file and ssh_public_key_path do not exist, Terraform generates them."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "enable_ansible_group_vars_domains" {
  description = "When true, Terraform writes Cloudflare hostnames into Ansible group_vars/<service>/terraform_domains.yml files."
  type        = bool
  default     = true
}

variable "ansible_group_vars_path" {
  description = "Path to the Ansible group_vars directory."
  type        = string
  default     = "../../../../../ansible_service_config/group_vars"
}

variable "enable_cloudflare_dns" {
  description = "When true, Terraform creates Cloudflare DNS records for service subdomains."
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Optional Cloudflare API token. Prefer using the CLOUDFLARE_API_TOKEN environment variable."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain, for example the zone ID for seang.shop."
  type        = string
  default     = ""
}

variable "cloudflare_dns_records" {
  description = "Cloudflare DNS records keyed by service name. A/AAAA records can use vm_index or content. CNAME records must use content."
  type = map(object({
    hostname             = string
    type                 = optional(string, "A")
    vm_index             = optional(number)
    content              = optional(string)
    proxied              = optional(bool, false)
    ttl                  = optional(number, 1)
    comment              = optional(string)
    create_ansible_group = optional(bool, true)
    ansible_group        = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for _, record in var.cloudflare_dns_records : trimspace(record.hostname) != ""])
    error_message = "Each Cloudflare DNS record hostname must be non-empty."
  }

  validation {
    condition     = alltrue([for _, record in var.cloudflare_dns_records : contains(["A", "AAAA", "CNAME"], upper(record.type))])
    error_message = "Cloudflare DNS record type must be A, AAAA, or CNAME."
  }

  validation {
    condition = alltrue([
      for _, record in var.cloudflare_dns_records :
      upper(record.type) == "CNAME"
      ? try(trimspace(record.content), "") != ""
      : (try(record.vm_index, null) != null || try(trimspace(record.content), "") != "")
    ])
    error_message = "A/AAAA records must set either vm_index or content. CNAME records must set content."
  }

  validation {
    condition = alltrue([
      for _, record in var.cloudflare_dns_records :
      upper(record.type) != "CNAME" || try(record.vm_index, null) == null
    ])
    error_message = "CNAME records must use content and should not set vm_index."
  }

  validation {
    condition     = alltrue([for _, record in var.cloudflare_dns_records : try(record.vm_index >= 1, true)])
    error_message = "vm_index is one-based and must be 1 or greater."
  }

  validation {
    condition     = alltrue([for _, record in var.cloudflare_dns_records : try(record.ttl == 1 || (record.ttl >= 60 && record.ttl <= 86400), false)])
    error_message = "Cloudflare DNS record ttl must be 1 for automatic, or between 60 and 86400 seconds."
  }

  validation {
    condition = alltrue([
      for _, record in var.cloudflare_dns_records :
      try(record.ansible_group, null) == null || can(regex("^[A-Za-z0-9_-]+$", record.ansible_group))
    ])
    error_message = "ansible_group must be a valid Ansible inventory group name."
  }
}
