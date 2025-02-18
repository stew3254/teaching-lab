images = [
  {remote = "ubuntu", image = "focal", aliases = ["f", "focal"], type = "container"},
  {remote = "ubuntu", image = "jammy", aliases = ["j", "jammy"], type = "container"},
  {remote = "ubuntu", image = "noble", aliases = ["n", "noble"], type = "container"},
  {remote = "ubuntu", image = "focal", aliases = ["fv", "focal-vm"], type = "virtual-machine"},
  {remote = "ubuntu", image = "jammy", aliases = ["jv", "jammy-vm"], type = "virtual-machine"},
  {remote = "ubuntu", image = "noble", aliases = ["nv", "noble-vm"], type = "virtual-machine"},
  {remote = "images", image = "ubuntu/jammy/desktop", aliases = ["jd", "jammy-desktop"], type = "virtual-machine"},
  {remote = "images", image = "ubuntu/noble/desktop", aliases = ["nd", "noble-desktop"], type = "virtual-machine"},
  {remote = "images", image = "kali/cloud", aliases = ["kali"], type = "container"},
]
enabled_labs = [
  "student-lab"
]
