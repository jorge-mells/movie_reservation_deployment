# NOTE: use comments to separate provider configs
terraform {
  required_version = "~> 1.16.5"
  required_providers {
    # NOTE: shared providers
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.4.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    # NOTE: libvirt specific
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
    # NOTE: hetzner specific
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
  backend "local" {
    path = "/var/lib/terraform/example.com/terraform.tfstate"
  }
}

# NOTE: shared provider config
provider "cloudinit" {}
provider "ansible" {}

# NOTE: libvirt specific config
provider "libvirt" {}

# NOTE: hetzner specific config
data "external" "hcloud_token" {
  program = ["bash", "-c", "bw get item hcloud_token | jq '{result: .notes}'"]
}

provider "hcloud" {
  token = data.external.hcloud_token.result.result
}
