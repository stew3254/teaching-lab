variable "enabled_labs" {
  description = "A list of labs we want to be built"
  type = set(string)
  default = []
}

variable "remote_name" {
  description = "The name of the LXD cluster"
  type = string
  default = null
}

variable "remote_addr" {
  description = "The address of the LXD cluster unit"
  type = string
  default = null
}

variable "public_network" {
  type = string
  description = "The ZeroTier public network id"
  default = null
}

variable "images" {
  description = "The images that will be cached on the server for quick access"
  type = list(object({
    remote = string
    image = string
    aliases = list(string)
    type = string
  }))
  default = null
}

variable "limits" {
  description = "Default resource limits for student projects"
  type = object({
    containers = optional(number)
    vms = optional(number)
    cores = number
    memory = string
    disk = string
    ips = optional(string)
    projects = optional(list(string))
  })
  default = {
    cores = 8
    memory = "24GiB"
    disk = "100GiB"
  }
}

variable "students" {
  description = "A map of students"
  type = map(object({
    name = string
    username = string
    ssh_key = string
    password = string
    join_public_network = bool
    ip = string
    ports = list(object({
      description = string
      protocol = string
      listen_port = string
      target_port = string
      target_address = string
    }))
    limits = optional(object({
      containers = optional(number)
      vms = optional(number)
      cores = optional(number)
      memory = optional(string)
      disk = optional(string)
    }))
  }))
  default = {}
}