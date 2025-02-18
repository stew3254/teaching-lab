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
  # for_each = var.students
  count = length(var.students)
  name = "${var.students[count.index].username}-lab"
  description = "${var.students[count.index].name}'s Lab"
  config = {
    "features.profiles" = true
    # "features.networks" = true
    "features.networks" = false
    "features.networks.zones" = true
    "features.images" = false
    "features.storage.buckets" = false
    "features.storage.volumes" = false

    # Add restrictions. More information here https://documentation.ubuntu.com/lxd/en/latest/reference/projects
    "restricted" = true
    # "restricted.backups" = "allow"
    # "restricted.devices.unix-hotplug" = "allow"
    # "restricted.devices.nic" = "managed"
    "restricted.devices.nic" = "allow"
    # "restricted.networks.access" = "${var.limits.nics} ${substr(var.students[count.index].username, 0, 11)}-net"
    "restricted.networks.subnets" = var.students[count.index].ips
    "restricted.networks.uplinks" = "UPLINK"
    "restricted.snapshots" = "allow"

    "limits.virtual-machines" = var.limits.vms
    "limits.containers" = var.limits.containers
    "limits.cpu" = var.limits.cores
    "limits.memory" = var.limits.memory
    "limits.disk" = var.limits.disk
    "limits.networks" = 2
  }
}

# Only allow ssh into the instance
resource "lxd_network_acl" "jump_acl" {
  # count = length(var.students)
  name = "jump-acl"
  # project = lxd_project.student[count.index].name

  egress = [
    {
      description      = "Allow all traffic out"
      action           = "allow"
      state            = "enabled"
    },
  ]

  ingress = [
    {
      description      = "Accept SSH"
      action           = "allow"
      source           = "@external"
      destination_port = "22"
      protocol         = "tcp"
      state            = "enabled"
    }
  ]
}

# Public network
resource "lxd_network" "student" {
  count = length(var.students)
  # Set a short network name
  name = "${substr(var.students[count.index].username, 0, 11)}-net"
  project = lxd_project.student[count.index].name
  type = "ovn"
  config = {
    "bridge.mtu" = 1442
    "network" = "UPLINK"
    "ipv4.address" = "192.168.10.1/24"
    "ipv4.dhcp" = true
    "ipv4.nat" = true
    "dns.domain" = "student.example.com"
    "ipv6.address" = "none"
    # Students are able to change these ACLs.
    # If you want to enforce them, you must do it from outside of OVN
    # "security.acls" = lxd_network_acl.jump_acl[count.index].name
    "security.acls" = lxd_network_acl.jump_acl.name
  }
}

# Default profile to use since "default" can't be used
resource "lxd_profile" "default" {
  count = length(var.students)
  name = "def"
  project = lxd_project.student[count.index].name
  description = "Default LXD Profile"

  # Limit the amount of resources used so that one container doesn't impact others
  config = {
    "limits.cpu" = 1
    "limits.memory" = "2GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[count.index].name
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

# Write the LXD profile Terraform manages into the default so we don't need to use the other name
data "external" "copy_default" {
  count = length(var.students)
  program = ["${path.root}/../scripts/set_default_profile.sh"]

  query = {
    "remote" = var.remote_name
    "profile" = "def"
    "project" = lxd_project.student[count.index].name
  }
}

resource "lxd_profile" "vm" {
  count = length(var.students)
  name = "vm"
  project = lxd_project.student[count.index].name
  description = "Ideal for Linux Server VMs"

  config = {
    "limits.cpu" = 2
    "limits.memory" = "4GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[count.index].name
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

resource "lxd_profile" "desktop" {
  count = length(var.students)
  name = "desktop"
  project = lxd_project.student[count.index].name
  description = "Ideal for Linux Desktop VMs"

  config = {
    "limits.cpu" = 4
    "limits.memory" = "6GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[count.index].name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "20GiB"
      pool = "remote"
    }
  }
}

resource "lxd_profile" "kali" {
  count = length(var.students)
  name = "kali"
  project = lxd_project.student[count.index].name
  description = "Ideal for Kali Linux"

  config = {
    "limits.cpu" = 4
    "limits.memory" = "8GiB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[count.index].name
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

resource "lxd_profile" "jump" {
  count = length(var.students)
  name = "jump"
  project = lxd_project.student[count.index].name
  description = "A profile to create a jump host"

  # Limit the amount of resources used so that one container doesn't impact others
  config = {
    "cloud-init.user-data" = file("${path.root}/../cloud-init/jump.yml")
    "user.ssh_key" = var.students[count.index].ssh_key == "" ? null : (endswith(var.students[count.index].ssh_key, ".pub") ? trimsuffix(file(var.students[count.index].ssh_key), "\n") : trimsuffix(file(format("%s.pub", var.students[count.index].ssh_key)), "\n"))
    "user.ssh_import_id" = var.students[count.index].ssh_import_id == "" ? null : var.students[count.index].ssh_import_id
    "user.password" = var.students[count.index].password
  }
}

resource "lxd_instance" "jump" {
  count = length(var.students)
  image = "n"
  name  = "jump"
  profiles = [lxd_profile.default[count.index].name, lxd_profile.jump[count.index].name]
  project = lxd_project.student[count.index].name

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student[count.index].name
      "ipv4.address" = "192.168.10.5"
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

  depends_on = [var.images]
}

# Assign a 'floating ip' to the jump host
resource "lxd_network_forward" "jump_forward" {
  count = length(var.students)
  project = lxd_project.student[count.index].name
  network = lxd_network.student[count.index].name
  listen_address = split(":", split("/", var.students[count.index].ips)[0])[1]
  config = {
    target_address = lxd_instance.jump[count.index].ipv4_address
  }
}