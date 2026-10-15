# NOTE: don't use old form with resource!!! use data resource instead
data "cloudinit_config" "init_content" {
  for_each      = local.servers
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-config.yaml", {
      fqdn               = each.value.hostname
      authorized_ssh_key = local.authorized_ssh_key
      ansible_user       = var.vm_info.ansible_user
    })
  }
}

# NOTE: this is the new dmacvicar pattern where you create this disk info and then place it in the pool
resource "libvirt_cloudinit_disk" "init_disk" {
  for_each  = local.servers
  name      = "${each.value.instance_id}-init.iso"
  user_data = data.cloudinit_config.init_content[each.key].rendered
  meta_data = yamlencode({
    instance-id    = each.value.instance_id
    local-hostname = each.value.hostname
  })
}

resource "libvirt_volume" "init_volume" {
  for_each = local.servers
  name     = "${each.value.instance_id}-cloudinit.iso"
  pool     = "default"

  create = {
    content = {
      # Use each.key to pull the matching path from the cloudinit disk map
      url = libvirt_cloudinit_disk.init_disk[each.key].path
    }
  }
}

resource "libvirt_volume" "base" {
  name = "base-volume"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.vm_info.base_volume_url
    }
  }
}

resource "libvirt_volume" "main_disk" {
  for_each = local.servers
  name     = "${each.value.instance_id}-disk.qcow2"
  pool     = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }
  capacity = each.value.disk_size

  backing_store = {
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
}
