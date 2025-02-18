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

# Accept LXD network resource
variable "public_network" {
  type = object({})
  description = "The public network"
  default = {}
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
    nics = optional(string)
    projects = optional(list(string))
  })
  default = null
}


variable "students" {
  description = "A map of students where the username is the key and is unique"
  type = map(object({
    name = string
    ssh_key = string
    ssh_import_id = string
    password = string
    ips = string
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
