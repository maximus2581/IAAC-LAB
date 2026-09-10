# Differencing VHDX disk linked to the master golden image
resource "hyperv_vhd" "vm_disk" {
  path        = "${var.vms_destination_path}\\${var.vm_name}.vhdx"
  parent_path = var.base_image_path
  vhd_type    = "Differencing"
}

# Optional extra raw data disks
resource "hyperv_vhd" "extra_disk" {
  for_each = { for d in var.extra_disks : d.location => d }
  path     = "${var.vms_destination_path}\\${var.vm_name}-disk-${each.key}.vhdx"
  vhd_type = "Dynamic"
  size     = each.value.size_gb * 1024 * 1024 * 1024
}

# Cloud-Init Network Configuration
resource "local_file" "network_config" {
  filename = "/tmp/${var.vm_name}_network_config"
  content  = templatefile("${path.module}/network_config.tftpl", {
    ip_address    = var.ip_address
    subnet_prefix = var.subnet_prefix
    default_gw    = var.default_gw
    dns_server    = var.dns_server
  })
}

# Cloud-Init Meta-Data
resource "local_file" "meta_data" {
  filename = "/tmp/${var.vm_name}_meta_data"
  content  = "instance-id: ${var.vm_name}\nhostname: ${var.vm_name}"
}

# Cloud-Init User-Data (injecting SSH public key)
resource "local_file" "user_data" {
  filename = "/tmp/${var.vm_name}_user_data"
  content  = <<-EOT
#cloud-config
manage_etc_hosts: true
runcmd:
  - echo '${trimspace(file(var.ssh_pub_key_path))}' >> /home/sysadmin/.ssh/authorized_keys
  - restorecon -Rv /home/sysadmin/.ssh
EOT
}

# NoCloud ISO generation via local-exec genisoimage
resource "null_resource" "create_iso" {
  triggers = {
    net_config = local_file.network_config.content
    user_data  = local_file.user_data.content
  }

  provisioner "local-exec" {
    command = "genisoimage -output ${var.iso_path_wsl}/config-${var.vm_name}.iso -volid cidata -joliet -rock -graft-points user-data=/tmp/${var.vm_name}_user_data meta-data=/tmp/${var.vm_name}_meta_data network-config=/tmp/${var.vm_name}_network_config"
  }
}

# Hyper-V Virtual Machine Instance
resource "hyperv_machine_instance" "vm" {
  name       = var.vm_name
  generation = 2

  processor_count      = var.cpu
  static_memory        = true
  memory_startup_bytes = var.ram_mb * 1024 * 1024

  vm_firmware {
    enable_secure_boot = "Off"
  }

  # OS Differencing disk
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.vm_disk.path
    resource_pool_name  = "Primordial"
  }

  # Dynamic extra disks
  dynamic "hard_disk_drives" {
    for_each = var.extra_disks
    content {
      controller_type     = "Scsi"
      controller_number   = 0
      controller_location = hard_disk_drives.value.location
      path                = hyperv_vhd.extra_disk[hard_disk_drives.value.location].path
      resource_pool_name  = "Primordial"
    }
  }

  # Cloud-Init ISO
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = "${var.iso_path_windows}\\config-${var.vm_name}.iso"
    resource_pool_name  = "Primordial"
  }

  network_adaptors {
    name        = "eth0"
    switch_name = var.hyperv_switch_name
  }

  lifecycle {
    ignore_changes = [
      hard_disk_drives,
      dvd_drives
    ]
  }

  depends_on = [
    null_resource.create_iso,
    hyperv_vhd.extra_disk
  ]
}

