packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# ------------------------------------------------------------------
# Variable Definitions
# ------------------------------------------------------------------

variable "golden_image_ip" {
  type        = string
  description = "Static IP assigned to the Golden Image during build"
}

variable "build_ssh_password" {
  type        = string
  description = "Temporary SSH password for Packer to connect during build"
  sensitive   = true
}

variable "admin_ssh_pub_key" {
  type        = string
  description = "Public SSH key for the sysadmin user"
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine in Hyper-V"
  default     = "packer-ol9-build"
}

variable "switch_name" {
  type        = string
  description = "Name of the Hyper-V virtual switch to attach to"
  default     = "LabSwitch"
}

variable "disk_size" {
  type        = number
  description = "Size of the OS disk in megabytes"
  default     = 40960
}

variable "iso_url" {
  type        = string
  description = "Full path or URL to the installation ISO"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the installation ISO"
}

variable "output_directory" {
  type        = string
  description = "Directory where Packer will export the finalized VM"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for provisioning"
  default     = "sysadmin"
}

variable "ssh_timeout" {
  type        = string
  description = "Timeout for SSH connection"
  default     = "20m"
}

variable "netmask" {
  type    = string
  default = "255.255.255.0"
}

variable "gateway" {
  type    = string
}

variable "dns_server" {
  type    = string
  default = "8.8.8.8"
}

variable "vm_hostname" {
  type    = string
  default = "golden-image-build"
}

variable "vm_timezone" {
  type    = string
  default = "Asia/Jerusalem"
}

# ------------------------------------------------------------------
# Source Configuration
# ------------------------------------------------------------------

source "hyperv-iso" "ol9_gold" {
  vm_name     = var.vm_name
  generation  = 2
  switch_name = var.switch_name

  # Create disk (value in megabytes)
  disk_size = var.disk_size 

  # The boot ISO will be downloaded automatically and cached locally
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # Directory where Packer will export the finalized VM
  output_directory = var.output_directory

  # SSH Credentials (must match the ones defined in ks.cfg)
  communicator = "ssh"
  ssh_host     = var.golden_image_ip
  ssh_username = var.ssh_username
  ssh_password = var.build_ssh_password
  ssh_timeout  = var.ssh_timeout 

  ssh_agent_auth = false
  ssh_pty        = true

  shutdown_command = "sudo shutdown -P now"

  # Attach the Kickstart file via a virtual CD-ROM dynamically
  cd_label = "cidata"
  cd_content = {
    "ks.cfg" = templatefile("${path.root}/packer_config/ks.pkrtpl.hcl", {
      ip_address     = var.golden_image_ip
      netmask        = var.netmask
      gateway        = var.gateway
      dns_server     = var.dns_server
      hostname       = var.vm_hostname
      vm_timezone    = var.vm_timezone
      ssh_username   = var.ssh_username
      build_password = var.build_ssh_password
    })
  }

  # GRUB UEFI boot commands for automated installation
  boot_wait = "10s"
  boot_command = [
    "e",                                 
    "<wait>",
    "<leftCtrlOn>n<leftCtrlOff><wait>", 
    "<leftCtrlOn>n<leftCtrlOff><wait>",  
    "<leftCtrlOn>e<leftCtrlOff><wait>",  
    " inst.ks=hd:LABEL=cidata:/ks.cfg",  
    "<wait>",
    "<leftCtrlOn>x<leftCtrlOff>"        
  ]
}

# ------------------------------------------------------------------
# Build Configuration
# ------------------------------------------------------------------

build {
  sources = ["source.hyperv-iso.ol9_gold"]

  # Final cleanup and key baking via shell provisioner
  provisioner "shell" {
    # Execute all commands strictly with sudo privileges
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    
    inline = [
      # 1. Deploy public SSH key for sysadmin (using parameterized variables)
      "mkdir -p /home/${var.ssh_username}/.ssh",
      "echo '${var.admin_ssh_pub_key}' > /home/${var.ssh_username}/.ssh/authorized_keys",
      "chmod 700 /home/${var.ssh_username}/.ssh",
      "chmod 600 /home/${var.ssh_username}/.ssh/authorized_keys",
      "chown -R ${var.ssh_username}:${var.ssh_username} /home/${var.ssh_username}/.ssh",

      # 2. Clean DNF package cache to reduce image size
      "dnf clean all",

      # 3. Reset cloud-init state for cloned VMs
      "cloud-init clean --logs",

      # 4. System generalization (Remove unique IDs and host keys)
      "rm -f /etc/ssh/ssh_host_*",
      "truncate -s 0 /etc/machine-id",
      "rm -f /etc/NetworkManager/system-connections/*.nmconnection",
      "rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg",

      "rm -f /etc/cloud/cloud.cfg.d/99-packer-ssh.cfg",
      "rm -f /etc/ssh/sshd_config.d/99-packer-ssh.conf"
    ]
  }
}