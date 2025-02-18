variable "enabled_labs" {
  type = set(string)
  description = "A list of labs we want to be built"
  default = []
}

variable "remote_name" {
  type = string
  description = "The name of the LXD cluster"
  default = null
}

variable "remote_addr" {
  type = string
  description = "The address of the LXD cluster unit"
  default = null
}

variable "images" {
  type = list(object({
    remote = string
    image = string
    aliases = list(string)
    type = string
  }))
  description = "The images that will be cached on the server for quick access"
  default = null
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
