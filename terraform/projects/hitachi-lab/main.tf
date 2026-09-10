locals {
  servers     = csvdecode(file("${path.module}/servers.csv"))
  servers_map = { for server in local.servers : server.server_name => server }
}

# Provision Hitachi Lab Instances via Reusable hyperv_vm Module
module "vm" {
  source   = "../../modules/hyperv_vm"
  for_each = local.servers_map

  vm_name       = each.key
  cpu           = tonumber(each.value.cpu)
  ram_mb        = tonumber(each.value.ram_mb)
  ip_address    = each.value.ip_address
  subnet_prefix = each.value.subnet_prefix
  default_gw    = each.value.default_gw
  dns_server    = each.value.dns_server

  base_image_path      = var.base_image_path
  vms_destination_path = var.vms_destination_path
  iso_path_wsl         = var.iso_path_wsl
  iso_path_windows     = var.iso_path_windows
  ssh_pub_key_path     = var.ssh_pub_key_path
  hyperv_switch_name   = var.hyperv_switch_name

  # No extra disks needed for standard lab nodes
  extra_disks = []
}

# Automatically generate the Hitachi Lab Ansible Inventory file
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventories/hitachi.ini"
  content  = templatefile("${path.module}/ansible_inventory.tftpl", {
    servers = local.servers
  })
}

