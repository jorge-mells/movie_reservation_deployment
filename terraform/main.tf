terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~>1.57.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~>2.4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~>2.4.0"
    }
  }
  required_version = "~>1.15.8"
}

# NOTE: this is a 'hack' for being too broke to pay for a proper secrets manager
# BUG: This is broken, but keep for reference and a way to fix. The problem is that
# this can potentially appear in logs and state files. Currently the best fix is via cli or using
# an actual secrets manager like infisical
# data "external" "hcloud_secret" {
#   program = ["bash", "-c", "echo '{\"token\": \"'$(bw get item 'hcloud_token' | jq -r '.notes')'\"}'"]
# }


variable "server_info" {
  type = map(string)
  default = {
    "fqdn" = "jorgemells.com"
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudinit" {

}

data "hcloud_ssh_key" "authorized_ssh_key" {
  name = "jorgemells@fedora"
}

data "cloudinit_config" "cloudinit" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config.yaml", {
      "fqdn"               = var.server_info.fqdn
      "authorized_ssh_key" = data.hcloud_ssh_key.authorized_ssh_key.public_key
    })
  }
}

data "hcloud_zone" "jorgemells" {
  name = "jorgemells.com"
}

resource "hcloud_firewall" "main" {
  name = "main"
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

data "hcloud_image" "main_server" {
  id = 421531170
}

resource "hcloud_server" "main" {
  name         = "main"
  location     = "fsn1"
  server_type  = "cpx12"
  image        = try(data.hcloud_image.main_server.id, "rocky-10")
  ssh_keys     = [data.hcloud_ssh_key.authorized_ssh_key.id]
  user_data    = data.cloudinit_config.cloudinit.rendered
  firewall_ids = [hcloud_firewall.main.id]
}

resource "hcloud_zone_rrset" "main" {
  zone = data.hcloud_zone.jorgemells.name
  name = "@"
  type = "A"

  ttl = 300
  records = [{
    value   = hcloud_server.main.ipv4_address
    comment = "main server"
  }]
}

resource "hcloud_zone_rrset" "wildcard" {
  zone = data.hcloud_zone.jorgemells.name
  name = "*"
  type = "A"

  ttl = 300
  records = [{
    value   = hcloud_server.main.ipv4_address
    comment = "main server"
  }]
}
