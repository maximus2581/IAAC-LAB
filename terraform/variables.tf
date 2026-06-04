# ======================================================================
# Hyper-V Connection Settings
# ======================================================================
variable "hyperv_host" {
  type        = string
  description = "IP address of the Windows Hyper-V host"
}

variable "hyperv_user" {
  type        = string
  description = "Username for WinRM connection to Hyper-V"
}

variable "hyperv_password" {
  type        = string
  description = "Password for WinRM connection"
  sensitive   = true
}

variable "hyperv_switch_name" {
  type        = string
  description = "Name of the Virtual Switch in Hyper-V"
  default     = "LabSwitch"
}

# ======================================================================
# Paths and Directories
# ======================================================================
variable "base_image_path" {
  type        = string
  description = "Windows path to the master Golden Image VHDX"
}

variable "vms_destination_path" {
  type        = string
  description = "Windows path where differencing disks will be stored"
}

variable "ssh_pub_key_path" {
  type        = string
  description = "WSL path to the SSH public key for Cloud-Init injection"
  default     = "/home/maxim/.ssh/id_ed25519.pub"
}

variable "iso_path_wsl" {
  type        = string
  description = "WSL path for saving generated Cloud-Init ISOs"
  default     = "/mnt/c/TF_ISOs"
}

variable "iso_path_windows" {
  type        = string
  description = "Windows path to the Cloud-Init ISOs (must map to iso_path_wsl)"
  default     = "C:\\TF_ISOs"
}