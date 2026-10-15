terraform {
  required_version = "~> 1.16.5"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.4.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~>1.0"
    }
  }
  backend "local" {
    path = "/var/lib/terraform/example.com/terraform.tfstate"
  }
}

provider "libvirt" {}
provider "cloudinit" {}
provider "ansible" {}
