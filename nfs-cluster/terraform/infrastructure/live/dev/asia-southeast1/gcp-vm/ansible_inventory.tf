locals {
  ansible_inventory_all_hosts = [
    for index, name in module.gcp_vm.instance_names :
    "${name} ansible_host=${module.gcp_vm.server_ips[index]} ansible_user=${module.gcp_vm.ssh_user} ansible_ssh_private_key_file=${pathexpand(var.ansible_ssh_private_key_path)}"
  ]

  ansible_inventory_hosts_by_index = {
    for index, name in module.gcp_vm.instance_names :
    index + 1 => "${name} ansible_host=${module.gcp_vm.server_ips[index]} ansible_user=${module.gcp_vm.ssh_user} ansible_ssh_private_key_file=${pathexpand(var.ansible_ssh_private_key_path)}"
  }

  # Dynamic path:
  # If Cloudflare DNS is enabled, A/AAAA records with vm_index can become
  # inventory groups automatically. The record key becomes the Ansible group
  # unless ansible_group is set.
  ansible_dns_service_targets = {
    for key, record in var.cloudflare_dns_records :
    (try(trimspace(record.ansible_group), "") != "" ? trimspace(record.ansible_group) : key) => {
      vm_index = record.vm_index
    }
    if var.enable_cloudflare_dns &&
    try(record.create_ansible_group, true) &&
    contains(["A", "AAAA"], upper(record.type)) &&
    try(record.vm_index, null) != null
  }

  ansible_effective_service_targets = length(var.ansible_service_targets) > 0 ? var.ansible_service_targets : local.ansible_dns_service_targets

  ansible_dynamic_inventory_groups = [
    for group in sort(keys(local.ansible_effective_service_targets)) : {
      name = group
      hosts = [
        try(
          local.ansible_inventory_hosts_by_index[local.ansible_effective_service_targets[group].vm_index],
          "INVALID_VM_INDEX_${local.ansible_effective_service_targets[group].vm_index}"
        )
      ]
    }
  ]

  ansible_fallback_inventory_groups = [
    for group in var.ansible_inventory_groups : {
      name  = group
      hosts = local.ansible_inventory_all_hosts
    }
  ]

  ansible_inventory_groups_for_template = length(local.ansible_effective_service_targets) > 0 ? local.ansible_dynamic_inventory_groups : local.ansible_fallback_inventory_groups
}

resource "terraform_data" "ansible_inventory_preflight" {
  input = local.ansible_effective_service_targets

  lifecycle {
    precondition {
      condition = alltrue([
        for _, target in local.ansible_effective_service_targets :
        target.vm_index >= 1 && target.vm_index <= length(module.gcp_vm.server_ips)
      ])
      error_message = "Each Ansible service target vm_index must point to an existing VM. Example: vm_index = 2 requires instance_count >= 2."
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = abspath("${path.module}/${var.ansible_inventory_path}")

  content = templatefile("${path.module}/templates/ansible_inventory.tftpl", {
    groups = local.ansible_inventory_groups_for_template
  })

  depends_on = [terraform_data.ansible_inventory_preflight]
}
