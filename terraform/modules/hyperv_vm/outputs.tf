output "vm_name" {
  description = "Virtual machine name"
  value       = hyperv_machine_instance.vm.name
}

output "ip_address" {
  description = "IP address of the VM"
  value       = var.ip_address
}

output "os_disk_path" {
  description = "Path to the OS differencing VHDX"
  value       = hyperv_vhd.vm_disk.path
}

output "extra_disk_paths" {
  description = "Paths to any extra VHDX disks created"
  value       = [for d in hyperv_vhd.extra_disk : d.path]
}

