variable "vm_name" {
  type        = string
  description = "Virtual Machine name"
}

variable "cpu" {
  type        = number
  description = "Number of vCPUs"
  default     = 2
}

variable "ram_mb" {
  type        = number
  description = "RAM size in MB"
  default     = 4096
}

variable "ip_address" {
  type        = string
  description = "Static IP address for the VM"
}

variable "subnet_prefix" {
  type        = string
  description = "Subnet CIDR prefix (e.g. 24)"
  default     = "24"
}

variable "default_gw" {
  type        = string
  description = "Default gateway IP"
  default     = "192.168.100.1"
}

variable "dns_server" {
  type        = string
  description = "DNS server IP"
  default     = "8.8.8.8"
}

variable "base_image_path" {
  type        = string
  description = "Windows path to the master base golden image VHDX"
}

variable "vms_destination_path" {
  type        = string
  description = "Windows path where VM differencing disks will be stored"
}

variable "iso_path_wsl" {
  type        = string
  description = "WSL path for saving Cloud-Init ISOs"
  default     = "/mnt/c/TF_ISOs"
}

variable "iso_path_windows" {
  type        = string
  description = "Windows path to Cloud-Init ISOs (mapping to iso_path_wsl)"
  default     = "C:\\TF_ISOs"
}

variable "ssh_pub_key_path" {
  type        = string
  description = "Path to SSH public key to embed in Cloud-Init"
  default     = "/home/maxim/.ssh/id_ed25519.pub"
}

variable "hyperv_switch_name" {
  type        = string
  description = "Hyper-V Virtual Switch Name"
  default     = "LabSwitch"
}

variable "extra_disks" {
  type = list(object({
    location = number
    size_gb  = number
  }))
  description = "List of extra data disks to attach to SCSI controller 0"
  default     = []
}

