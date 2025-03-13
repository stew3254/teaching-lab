terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = ">= 2.4.0"
    }
  }
}

provider "lxd" {
  remote {
    name     = var.remote_name
    address  = var.remote_addr
    default = true
  }
}

# Cache common images from the Remote
resource "lxd_cached_image" "images" {
  count = length(var.images)
  source_remote = var.images[count.index].remote
  source_image = var.images[count.index].image
  aliases = var.images[count.index].aliases
  type = var.images[count.index].type
  project = "default"
}

module "student-lab" {
  # Create the module conditionally if it is in the set
  for_each = {
    for k, v in var.enabled_labs: k => v
    if v == "student-lab"
  }
  source = "./modules/student-lab"
  images = lxd_cached_image.images
  remote_name = var.remote_name
  public_network = var.public_network
  limits = var.limits
  students = var.students
}

module "soc-lab" {
  # Create the module conditionally if it is in the set
  for_each = {
    for k, v in var.enabled_labs: k => v
    if v == "soc-lab"
  }
  source = "./modules/soc-lab"
}

module "pentest-lab" {
  # Create the module conditionally if it is in the set
  for_each = {
    for k, v in var.enabled_labs: k => v
    if v == "pentest-lab"
  }
  source = "./modules/pentest-lab"
}

module "it-lab" {
  # Create the module conditionally if it is in the set
  for_each = {
    for k, v in var.enabled_labs: k => v
    if v == "it-lab"
  }
  source = "./modules/it-lab"
}

module "assignment-lab" {
  # Create the module conditionally if it is in the set
  for_each = {
    for k, v in var.enabled_labs: k => v
    if v == "assignment-lab"
  }
  source = "./modules/assignment-lab"
}