locals {
  servers     = csvdecode(file("${path.module}/servers.csv"))
  servers_map = { for server in local.servers : server.server_name => server }
}

# Provision Ceph Node Instances via the Reusable hyperv_vm Module
module "ceph_node" {
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

  # Attach the 50GB OSD Raw Data Disk at SCSI location 2
  extra_disks = [
    {
      location = 2
      size_gb  = tonumber(each.value.osd_disk_gb)
    }
  ]
}

# Automatically generate the Ceph Ansible Inventory file
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventories/ceph.ini"
  content  = templatefile("${path.module}/ansible_inventory.tftpl", {
    servers = local.servers
  })
}

