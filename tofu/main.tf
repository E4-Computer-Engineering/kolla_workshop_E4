terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

provider "openstack" {
}

variable "n" {
  type    = number
  default = 2
}

# Base IP for vm_net_2 (host number within the subnet)
variable "vm_net_2_base_ip" {
  type    = number
  default = 105
}

# Networks
data "openstack_networking_network_v2" "vm_net" {
  name = "vm_net"
}

data "openstack_networking_network_v2" "vm_net_2" {
  name = "vm_net_2"
}

# Subnet for vm_net_2 (needed to compute IPs / set subnet_id in fixed_ip)
data "openstack_networking_subnet_v2" "vm_net_2_subnet" {
  name = "vm_net_int"
}

# Image
data "openstack_images_image_v2" "ubuntu24" {
  name = "ubuntu24.04"
}

# Flavor
data "openstack_compute_flavor_v2" "b_boot_vm" {
  name = "b_boot_vm"
}

# Primary network ports (DHCP on vm_net)
resource "openstack_networking_port_v2" "other_vm_primary_port" {
  count              = var.n
  name               = "workshop-vm-${count.index + 1}-net1-port"
  network_id         = data.openstack_networking_network_v2.vm_net.id
  admin_state_up     = true
  port_security_enabled = false
}

# Secondary network ports (vm_net_2)
resource "openstack_networking_port_v2" "other_vm_secondary_port" {
  count              = var.n
  name               = "workshop-vm-${count.index + 1}-net2-port"
  network_id         = data.openstack_networking_network_v2.vm_net_2.id
  admin_state_up     = true
  port_security_enabled = false

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.vm_net_2_subnet.id
    ip_address = cidrhost(
      data.openstack_networking_subnet_v2.vm_net_2_subnet.cidr,
      var.vm_net_2_base_ip + (count.index * 5)
    )
  }
}

# Docker Registry VM --> Create single VM using CLI or Horizon

# Other VMs — use the ports we created above (primary + secondary)
resource "openstack_compute_instance_v2" "other_vms" {
  count           = var.n
  name            = "workshop-vm-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu24.id
  flavor_id       = data.openstack_compute_flavor_v2.b_boot_vm.id
  key_pair        = "pisakey"
  security_groups = ["default"]

  network {
    port = openstack_networking_port_v2.other_vm_primary_port[count.index].id
  }

  network {
    port = openstack_networking_port_v2.other_vm_secondary_port[count.index].id
  }

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu24.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 50
    volume_type           = "nfsZone"
    delete_on_termination = true
  }

  block_device {
    source_type           = "blank"
    boot_index            = 1
    destination_type      = "volume"
    volume_size           = 50
    volume_type           = "nfsZone"
    delete_on_termination = true
  }
}

# Output to show assigned IPs
output "other_vms_net2_ips" {
  value = [
    for i in range(var.n) : openstack_networking_port_v2.other_vm_secondary_port[i].fixed_ip[0].ip_address
  ]
  description = "Static IPs assigned on vm_net_2 for the workshop VMs"
}