terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
    ansible = {
      source = "ansible/ansible"
    }
  }
}
