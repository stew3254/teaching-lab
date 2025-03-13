# variable "remote_name" {
#   type = string
#   description = "The name of the LXD cluster"
#   default = null
# }
#
# variable "remote_addr" {
#   type = string
#   description = "The address of the LXD cluster unit"
#   default = null
# }

variable "remote_name" {
  type = string
  description = "The name of the LXD cluster"
  default = null
}

variable "public_network" {
  type = string
  description = "The ZeroTier public network id"
  default = null
}

# Accept LXD images resource
variable "images" {
  type = list(object({}))
  description = "The images that will be cached on the server for quick access"
  default = []
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
  default = null
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
