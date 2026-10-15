resource "libvirt_network" "net" {
  name = "custom"
  domain = {
    name = var.network_info.domain
  }
  forward = {
    mode = "nat"
  }
  ips = [{
    address = cidrhost(var.network_info.cidr, 1)
    netmask = cidrnetmask(var.network_info.cidr)
    dhcp = {
      hosts = [
        for _, server in local.servers : {
          ip   = server.ip
          name = server.hostname
        }

      ]
    }
  }]
}
