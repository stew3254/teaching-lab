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
  name = "student"
  description = "Project for a specific student"
  config = {
    "features.profiles" = true
    "features.networks" = true
    "features.networks.zones" = true
    "features.images" = false
    "features.storage.buckets" = false
    "features.storage.volumes" = false
    "restricted.networks.subnets" = "UPLINK:192.168.200.251/32"
  }
}

# Only allow ssh into the instance
resource "lxd_network_acl" "jump_acl" {
  name = "jump-acl"
  project = lxd_project.student.name

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
  name = "student"
  project = lxd_project.student.name
  type = "ovn"
  config = {
    "bridge.mtu" = 1442
    "network" = "UPLINK"
    "ipv4.address" = "192.168.10.1/24"
    "ipv4.dhcp" = true
    "ipv4.nat" = true
    "dns.domain" = "student.example.com"
    "ipv6.address" = "none"
    "security.acls" = lxd_network_acl.jump_acl.name
  }
}

# Default profile to use since "default" can't be used
resource "lxd_profile" "student" {
  name = "def"
  project = lxd_project.student.name
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
      network = lxd_network.student.name
    }
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      size = "5GiB"
      pool = "remote"
    }
  }
}

# Write the LXD profile Terraform manages into the default so we don't need to use the other name
data "external" "copy_default" {
  program = ["${path.root}/../scripts/set_default_profile.sh"]

  query = {
    "remote" = var.remote_name
    "profile" = lxd_profile.student.name
    "project" = lxd_project.student.name
  }
}

resource "lxd_profile" "jump" {
  name = "jump"
  project = lxd_project.student.name
  description = "A profile to create a jump host"

  # Limit the amount of resources used so that one container doesn't impact others
  config = {
    "cloud-init.user-data" = file("${path.root}/../cloud-init/jump.yml")
    "user.ssh_key" = var.ssh_key == "" ? null : (endswith(var.ssh_key, ".pub") ? trimsuffix(file(var.ssh_key), "\n") : trimsuffix(file(format("%s.pub", var.ssh_key)), "\n"))
    "user.ssh_import_id" = var.ssh_import_id == "" ? null : var.ssh_import_id
    "user.password" = var.password
    "user.pro_token" = var.pro_token == "" ? null : var.pro_token
  }
}

resource "lxd_instance" "jump" {
  image = "n"
  ephemeral = true
  name  = "jump"
  profiles = [lxd_profile.student.name, lxd_profile.jump.name]
  project = lxd_project.student.name

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = lxd_network.student.name
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
  project = lxd_project.student.name
  network = lxd_network.student.name
  listen_address = "192.168.200.251"
  config = {
    target_address = lxd_instance.jump.ipv4_address
  }
}