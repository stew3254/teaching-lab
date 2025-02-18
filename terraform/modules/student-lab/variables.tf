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


variable "ssh_key" {
  type = string
  default = ""
}

variable "ssh_import_id" {
  type = string
  default = ""
}

variable "password" {
  type = string
  default = "ubuntu"
}

variable "pro_token" {
  type = string
  default = ""
}