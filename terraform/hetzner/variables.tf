variable "network_info" {
  type = object({
    cidr         = string
    domain       = string
    network_zone = string
  })
  default = {
    cidr         = "192.168.125.0/24"
    domain       = "jorgemells.com"
    network_zone = "eu-central"
  }
}

variable "vm_info" {
  type = object({
    vm_groups = list(object({
      name        = string
      count       = number
      server_type = string
      image       = string
      location    = string
    }))
    ansible_user         = string
    ssh_public_key_path  = string
    ssh_private_key_path = string
  })
  default = {
    vm_groups = [{
      name        = "default"
      count       = 1
      server_type = "cpx22" # WARN: this is super expensive!! Don't keep running for long!!
      image       = "centos-stream-10"
      location    = "nbg1"
    }]
    ansible_user         = "ansible"
    ssh_public_key_path  = "~/.ssh/id_ed25519.pub"
    ssh_private_key_path = "~/.ssh/id_ed25519"
  }
}

locals {
  prefix                     = parseint(split("/", var.network_info.cidr)[1], 10)
  max_usable_ips             = pow(2, 32 - local.prefix) - 2
  authorized_ssh_public_key  = file(pathexpand(var.vm_info.ssh_public_key_path))
  authorized_ssh_private_key = file(pathexpand(var.vm_info.ssh_private_key_path))

  # flatten groups into a list of per-vm objects with group info attached
  vm_list = flatten([
    for group in var.vm_info.vm_groups : [
      for i in range(group.count) : {
        server_type = group.server_type
        group       = group.name
        image       = group.image
        location    = group.location
      }
    ]
  ])

  # slice to max usable IPs then build the map
  servers = { for i, vm in slice(local.vm_list, 0, min(length(local.vm_list), local.max_usable_ips)) : "vm${i}" => merge(vm, {
    hostname    = "vm${i}.${var.network_info.domain}"
    ip          = cidrhost(var.network_info.cidr, i + 2)
    instance_id = "vm${i}"
  }) }
}
