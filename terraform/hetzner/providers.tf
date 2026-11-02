terraform {
  required_providers {
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
    ansible = {
      source = "ansible/ansible"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}
