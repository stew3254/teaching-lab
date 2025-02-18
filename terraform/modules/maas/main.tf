terraform {
  required_providers {
    maas = {
      source  = "canonical/maas"
      version = "2.4.0"
    }
  }
}

provider "maas" {
  api_version = "2.0"
  api_key     = file("../../../secrets/maas-token")
  api_url     = var.maas_url
}

locals {
  machines = ["top", "middle", "bottom"]
}

# data "maas_machine" "mini_pcs" {
#   count = length(local.machines)
#   hostname = local.machines[count.index]
# }

# Set up tags for mini pcs
resource "maas_tag" "kvm_hosts" {
  name = "kvm-host"
  machines = local.machines
}

resource "maas_tag" "mini_pcs" {
  count = length(local.machines)
  name = local.machines[count.index]
}

# resource "maas_vm_host" "nahl" {
#   type = "lxd"
#   power_address = "10.244.120.8"
#   cpu_over_commit_ratio = 10
#   memory_over_commit_ratio = 10
#   tags = [
#     "pod-console-logging",
#     "kvm",
#   ]
# }

# Create a vm which can be used as a juju controller
# resource "maas_vm_host_machine" "juju_controller" {
#   vm_host = maas_vm_host.nahl.id
#   cores = 2
#   memory = 4096
#   storage_disks {
#     size_gigabytes = 25
#   }
# }

# resource "maas_tag" "juju_controller" {
#   count = length(local.machines)
#   name = local.machines[count.index]
# }

resource "maas_instance" "mini_pcs" {
  count = length(local.machines)
  allocate_params {
    hostname = local.machines[count.index]
  }
  deploy_params {
    distro_series = "jammy"
    user_data = file("../../../cloud-init/microcloud.yml")
  }
  timeouts {
    create = "30m"
    delete = "10m"
  }
}