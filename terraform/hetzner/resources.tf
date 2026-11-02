resource "hcloud_network" "default" {
  name     = var.network_info.domain
  ip_range = var.network_info.cidr
}

resource "hcloud_network_subnet" "default" {
  network_id   = hcloud_network.default.id
  type         = "cloud"
  network_zone = var.network_info.network_zone
  ip_range     = var.network_info.cidr # same as the network itself
}

resource "hcloud_firewall" "default" {
  name = "default"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

data "cloudinit_config" "init_content" {
  for_each      = local.servers
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-config.yaml", {
      fqdn                      = each.value.hostname
      authorized_ssh_public_key = local.authorized_ssh_public_key
      ansible_user              = var.vm_info.ansible_user
    })
  }
}

resource "hcloud_ssh_key" "default" {
  name       = "default"
  public_key = local.authorized_ssh_public_key
}

resource "hcloud_server" "vms" {
  for_each     = local.servers
  name         = each.value.instance_id
  server_type  = each.value.server_type
  image        = each.value.image
  location     = each.value.location
  user_data    = data.cloudinit_config.init_content[each.key].rendered
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.default.id]
  network {
    network_id = hcloud_network.default.id
    ip         = each.value.ip
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  connection {
    type        = "ssh"
    user        = var.vm_info.ansible_user
    private_key = local.authorized_ssh_private_key
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait || [ $? -eq 2 ]"]
  }
}

resource "ansible_host" "vm" {
  for_each = local.servers

  name   = each.value.hostname
  groups = [each.value.group, "terraform"]

  variables = {
    ansible_host = hcloud_server.vms[each.key].ipv4_address
    ansible_user = var.vm_info.ansible_user
    domain_name  = var.network_info.domain
  }
}

resource "ansible_group" "terraform" {
  name = "terraform"
  variables = {
  }
}
