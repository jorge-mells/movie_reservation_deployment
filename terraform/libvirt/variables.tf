variable "network_info" {
  type = object({
    cidr   = string
    domain = string
  })
  default = {
    cidr   = "192.168.125.0/30"
    domain = "example.com"
  }
}

variable "vm_info" {
  type = object({
    vm_groups = list(object({
      name      = string
      count     = number
      vcpu      = number
      memory    = number # GiB
      disk_size = number # GiB
    }))
    base_volume_url = string
    ansible_user    = string
    ssh_key_path    = string
  })
  default = {
    vm_groups = [{
      name      = "default"
      count     = 1
      vcpu      = 1
      memory    = 1
      disk_size = 10
    }]
    base_volume_url = "https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-10-20261006.0.x86_64.qcow2"
    ansible_user    = "ansible"
    ssh_key_path    = "~/.ssh/id_ed25519.pub"
  }
}

locals {
  prefix             = parseint(split("/", var.network_info.cidr)[1], 10)
  max_usable_ips     = pow(2, 32 - local.prefix) - 2
  authorized_ssh_key = file(pathexpand(var.vm_info.ssh_key_path))

  # flatten groups into a list of per-vm objects with group info attached
  vm_list = flatten([
    for group in var.vm_info.vm_groups : [
      for i in range(group.count) : {
        vcpu      = group.vcpu
        memory    = group.memory
        disk_size = group.disk_size * pow(1024, 3)
        group     = group.name
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
