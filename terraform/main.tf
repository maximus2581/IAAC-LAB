locals {
  # Decode server metadata from the CSV source file
  servers     = csvdecode(file("${path.module}/servers.csv"))
  servers_map = { for server in local.servers : server.server_name => server }
}

# Create Differencing VHDX disks linked to the Master Golden Image
resource "hyperv_vhd" "vm_disk" {
  for_each    = local.servers_map
  path        = "${var.vms_destination_path}\\${each.key}.vhdx"
  parent_path = var.base_image_path
  vhd_type    = "Differencing"
}

# Generate Cloud-Init Network Configuration files
resource "local_file" "network_config" {
  for_each = local.servers_map
  filename = "/tmp/${each.key}_network_config"
  content  = templatefile("${path.module}/network_config.tftpl", {
    ip_address    = each.value.ip_address
    subnet_prefix = each.value.subnet_prefix
    default_gw    = each.value.default_gw
    dns_server    = each.value.dns_server
  })
}

# Generate Cloud-Init Meta-Data files
resource "local_file" "meta_data" {
  for_each = local.servers_map
  filename = "/tmp/${each.key}_meta_data"
  content  = "instance-id: ${each.key}\nhostname: ${each.key}"
}

# Generate Cloud-Init User-Data files (empty basic config, SSH keys are injected)
resource "local_file" "user_data" {
  for_each = local.servers_map
  filename = "/tmp/${each.key}_user_data"
  content  = <<-EOT
#cloud-config
manage_etc_hosts: true
runcmd:
  - echo '${trimspace(file(var.ssh_pub_key_path))}' >> /home/sysadmin/.ssh/authorized_keys
  - restorecon -Rv /home/sysadmin/.ssh
EOT
}

# Generate NoCloud ISO files via WSL local-exec
resource "null_resource" "create_iso" {
  for_each = local.servers_map

  triggers = {
    net_config = local_file.network_config[each.key].content
    user_data  = local_file.user_data[each.key].content
  }

  provisioner "local-exec" {
    command = "genisoimage -output ${var.iso_path_wsl}/config-${each.key}.iso -volid cidata -joliet -rock -graft-points user-data=/tmp/${each.key}_user_data meta-data=/tmp/${each.key}_meta_data network-config=/tmp/${each.key}_network_config"
  }
}

# Provision Hyper-V Virtual Machine Instances
resource "hyperv_machine_instance" "vm" {
  for_each   = local.servers_map
  name       = each.key
  generation = 2

  # Dynamic resource allocation parsed directly from the CSV file
  processor_count      = tonumber(each.value.cpu)
  static_memory        = true
  memory_startup_bytes = tonumber(each.value.ram_mb) * 1024 * 1024

  vm_firmware {
    enable_secure_boot = "Off"
  }

  # Attach the dynamic differencing disk
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.vm_disk[each.key].path
  }

  # Attach the generated Cloud-Init ISO configuration disk
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = "${var.iso_path_windows}\\config-${each.key}.iso"
  }

  network_adaptors {
    name        = "eth0"
    switch_name = var.hyperv_switch_name
  }

  depends_on = [null_resource.create_iso]
}

# Automatically generate the Ansible Inventory file upon successful provisioning
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = templatefile("${path.module}/ansible_inventory.tftpl", {
    servers = local.servers
  })

  depends_on = [hyperv_machine_instance.vm]
}