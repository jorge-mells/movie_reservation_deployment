resource "ansible_host" "vm" {
  for_each = local.servers

  name   = each.value.hostname
  groups = [each.value.group, "terraform"]

  variables = {
    ansible_host = each.value.ip
    ansible_user = var.vm_info.ansible_user
    domain_name  = var.network_info.domain
  }
}

resource "ansible_group" "terraform" {
  name = "terraform"
  variables = {
  }
}
