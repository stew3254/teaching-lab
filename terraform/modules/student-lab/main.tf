terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = ">= 2.4.0"
    }
  }
}

# Student project
resource "lxd_project" "student" {
  for_each = var.students
  # count = length(var.students)
  name = "${each.key}-lab"
  description = "${each.value.name}'s Lab"
  config = {
    "features.profiles" = true
    "features.networks" = true
    "features.networks.zones" = true
    "features.images" = false
    "features.storage.buckets" = false
    "features.storage.volumes" = true

    # Add restrictions. More information here https://documentation.ubuntu.com/lxd/en/latest/reference/projects
    "restricted" = true
    # "restricted.backups" = "allow"
    # "restricted.devices.unix-hotplug" = "allow"
    # "restricted.devices.nic" = "managed"
    "restricted.devices.nic" = "allow"
    # "restricted.networks.access" = "${var.limits.nics} ${substr(each.value.username, 0, 11)}-net"
    # "restricted.networks.subnets" = each.value.ips
    "restricted.networks.uplinks" = "UPLINK"
    "restricted.snapshots" = "allow"
    # "restricted.virtual-machines.lowlevel" = "allow"

    "limits.virtual-machines" = var.limits.vms
    "limits.containers" = var.limits.containers
    "limits.cpu" = var.limits.cores
    "limits.memory" = var.limits.memory
    "limits.disk" = var.limits.disk
    "limits.networks" = 4
  }
}

# Only allow ssh into the instance
resource "lxd_network_acl" "jump_acl" {
  for_each = var.students
  name = "jump-acl"
  project = lxd_project.student[each.key].name

  egress = [
    {
      description      = "Allow all traffic out"
      action           = "allow"
      state            = "enabled"
    },
  ]

  ingress = length(each.value.ports) == 0 ? null : [
    for i in each.value.ports:
      {
        description      = i.description
        action           = "allow"
        source           = "@external"
        destination_port = i.listen_port
        protocol         = i.protocol
        state            = "enabled"
      }
  ]
}

# Create the student's network
resource "lxd_network" "student" {
  for_each = var.students
  # Set a short network name
  name = "${substr(each.value.username, 0, 11)}-net"
  project = lxd_project.student[each.key].name
  type = "ovn"
  config = {
    "bridge.mtu" = 1442
    "network" = "UPLINK"
    "ipv4.address" = "192.168.10.1/24"
    "ipv4.dhcp" = true
    "ipv4.nat" = true
    "dns.domain" = "~student.example.com"
    "ipv6.address" = "none"
    # Students are able to change these ACLs.
    # If you want to enforce them, you must do it from outside of OVN
    # "security.acls" = lxd_network_acl.jump_acl[count.index].name
    "security.acls" = lxd_network_acl.jump_acl[each.key].name
  }
}

# Default profile
resource "lxd_profile" "default" {
  for_each = var.students
  name = "default"
  project = lxd_project.student[each.key].name
  description = "Default LXD Profile"

  # Limit the amount of resources used so that one container doesn't impact others
  config = {
    "limits.cpu" = 1
    "limits.memory" = "1GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[each.key].name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "8GiB"
      pool = "remote"
    }
  }
}

resource "lxd_profile" "vm" {
  for_each = var.students
  name = "vm"
  project = lxd_project.student[each.key].name
  description = "Ideal for Linux Server VMs"

  config = {
    "limits.cpu" = 2
    "limits.memory" = "2GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[each.key].name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "10GiB"
      pool = "remote"
    }
  }
}

resource "lxd_profile" "desktop" {
  for_each = var.students
  name = "desktop"
  project = lxd_project.student[each.key].name
  description = "Ideal for Linux Desktop VMs"

  config = {
    "limits.cpu" = 2
    "limits.memory" = "4GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[each.key].name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "15GiB"
      pool = "remote"
    }
  }
}

# Create a volume for the student's home directory.
# This allows us to keep their files in case the kali VM breaks
resource "lxd_volume" "home" {
  for_each = var.students
  name = "home"
  project = lxd_project.student[each.key].name
  pool = "remote-fs"
  config = {
    size = "10GiB"
  }
}

resource "lxd_profile" "kali" {
  for_each = var.students
  name = "kali"
  project = lxd_project.student[each.key].name
  description = "Used for Kali Linux Desktop"

  config = {
    "security.secureboot" = false
    "limits.cpu" = 2
    "limits.memory" = "6GiB"
    "cloud-init.user-data" = file("${path.root}/../cloud-init/kali-desktop.yml")
    "user.username" = each.value.username
    "user.ssh_key" = endswith(each.value.ssh_key, ".pub") ? trimsuffix(file(each.value.ssh_key), "\n") : trimsuffix(file("${each.value.ssh_key}.pub"), "\n")
    "user.password" = each.value.password
    "user.public_network" = each.value.join_public_network ? var.public_network : null
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[each.key].name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "30GiB"
      pool = "remote"
    }
  }
}

resource "lxd_instance" "kali" {
  for_each = var.students
  image = "kv"
  name  = "kali"
  type = "virtual-machine"
  profiles = [lxd_profile.default[each.key].name, lxd_profile.kali[each.key].name]
  project = lxd_project.student[each.key].name

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[each.key].name
      "ipv4.address" = "192.168.10.5"
    }
  }

  device {
    name = "home"
    type = "disk"
    properties = {
      path = "/home"
      source = lxd_volume.home[each.key].name
      pool = "remote-fs"
    }
  }

  timeouts = {
    create = "60m"
  }

  execs = {
    "wait_cloud_init" = {
      command = ["cloud-init", "status", "--wait"]
      enabled = true
      trigger = "once"
      record_output = true
      fail_on_error = true
    }
  }
}

# Snapshot the machine once it's been created in case we need to go back to it
# This will save us from having to recreate the machine in most cases
resource "lxd_snapshot" "kali_machine" {
  for_each = var.students
  name     = "base"
  project = lxd_project.student[each.key].name
  instance = lxd_instance.kali[each.key].name
  stateful = false
}

# Currently cannot snapshot volumes. Disable snapshots for now
# resource "lxd_snapshot" "kali_home" {
#   for_each = var.students
#   name     = "base"
#   project = lxd_project.student[each.key].name
#   # instance = lxd_volume.home[each.key].name
#   instance = "test"
#   stateful = false
# }

# Assign a 'floating ip' to the jump host
resource "lxd_network_forward" "jump_forward" {
  for_each = var.students
  project = lxd_project.student[each.key].name
  network = lxd_network.student[each.key].name
  listen_address = each.value.ip
  config = {
    target_address = length(each.value.ports) > 0 ? null : lxd_instance.kali[each.key].ipv4_address
  }
  ports = length(each.value.ports) > 0 ? each.value.ports : null
}