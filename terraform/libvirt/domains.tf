resource "libvirt_domain" "vms" {
  for_each    = local.servers
  name        = each.value.instance_id
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "GiB"
  vcpu        = each.value.vcpu
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
    apic = {

    }
  }
  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.main_disk[each.key].pool
            volume = libvirt_volume.main_disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.init_volume[each.key].pool
            volume = libvirt_volume.init_volume[each.key].name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        type = "network"
        source = {
          network = {
            network = libvirt_network.net.name
          }
        }
        wait_for_ip = {
          source = "any"
        }
      }
    ]


    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = 0
        }
      }
    ]

  }
  running = true
}
