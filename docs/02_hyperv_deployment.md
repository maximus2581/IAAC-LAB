# Phase 2: Infrastructure Provisioning (Hyper-V & Terraform)

In this phase, we deploy the lab topology (SAM4H server and Storage Emulators) on Microsoft Hyper-V. Instead of creating full, heavy clones of the OS, we use **Terraform** to provision **Differencing VHDX Disks** linked to our Phase 1 Golden Image. 

This approach provisions the entire lab in seconds and saves dozens of gigabytes of disk space. Operating system configuration (IPs, Hostnames, SSH Keys) is injected dynamically via **Cloud-Init (NoCloud ISOs)**.

## 🛠 Under the Hood: The Provisioning Flow
1. Terraform reads the target topology from the `servers.csv` file.
2. It creates lightweight Differencing Disks linked to the master Golden Image.
3. It dynamically generates Cloud-Init configuration files (`network-config`, `user-data`, `meta-data`) and packs them into temporary ISO files using local WSL commands.
4. The Hyper-V provider spins up Generation 2 VMs, attaching both the OS disk and the configuration ISO.
5. Upon successful creation, Terraform automatically renders the `inventory.ini` file for the next Ansible phase.

## 📋 Prerequisites
* **Terraform** installed on your system.
* **WSL (Windows Subsystem for Linux)** with `genisoimage` installed (required for local-exec ISO generation).
* A successfully built Golden Image from Phase 1.
* A configured Hyper-V Virtual Switch (default: `LabSwitch`).

## ⚙️ Configuration

### 1. Topology Definition (`servers.csv`)
Define your required virtual machines in the CSV file located in the `terraform/` directory.
```csv
server_name,ip_address,subnet_prefix,default_gw,dns_server,role,cpu,ram_mb
sam4h-srv,192.168.100.100,24,192.168.100.1,8.8.8.8,sam4h,4,8192
emu-stor-01,192.168.100.101,24,192.168.100.1,8.8.8.8,storage_emulator,2,4096
```

### 2. Environment Variables (terraform.tfvars)
> ⚠️ CRITICAL: Never commit real passwords to version control.
Create a file named terraform.tfvars in the root of your terraform/ directory. Terraform will automatically load these values.

Example terraform.tfvars format:
```
# --- Hyper-V WinRM Connection ---
hyperv_host     = "10.0.0.9"
hyperv_user     = "maximus"
hyperv_password = "YourSuperSecretPasswordHere!"

# --- Infrastructure Paths ---
base_image_path      = "C:\\Users\\maxim\\Documents\\Lab\\VM\\template\\OL9_5-template\\Virtual Hard Disks\\packer-ol9-build.vhdx"
vms_destination_path = "C:\\Users\\maxim\\Documents\\Lab\\VM\\Virtual Hard Disks"

# --- WSL / Windows Path Mapping for Cloud-Init ---
# The WSL path where the genisoimage command will save the ISO
iso_path_wsl     = "/mnt/c/TF_ISOs"
# The exact same directory, but formatted for Windows Hyper-V to mount
iso_path_windows = "C:\\TF_ISOs"

# --- Credentials ---
ssh_pub_key_path = "/home/maxim/.ssh/id_ed25519.pub"
```

## 🚀 Execution Steps

### 1. Open your WSL terminal and navigate to the Terraform directory:
```bash
cd terraform/
```

### 2. Initialize the working directory (downloads the Hyper-V provider):
```bash
terraform init
```

### 3. Review the execution plan to ensure paths and resources are correct:
```bash
terraform plan
```

### 4. Apply the configuration to provision the infrastructure:
```bash
terraform apply -auto-approve
```

## 📂 Result
Once the apply is complete, your Hyper-V manager will display the running VMs. They will automatically configure their network interfaces and accept SSH connections using your injected Ed25519 key.

Terraform will also generate the inventory.ini file in the ansible/ folder, meaning you are fully ready to proceed to Phase 3!