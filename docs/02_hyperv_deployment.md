# Phase 2: Infrastructure Provisioning (Hyper-V & Terraform)

In this phase, we provision virtual machines on Microsoft Hyper-V using **Terraform**. To maximize reusability, eliminate state drift, and isolate failure domains, the infrastructure is structured as a **Multi-Project Architecture** backed by a shared Terraform module.

---

## 🏗 Directory Architecture

```
terraform/
├── modules/
│   └── hyperv_vm/             # Reusable Hyper-V VM Module
│       ├── main.tf            # VHDX creation, Cloud-Init ISOs, VM instance
│       ├── variables.tf       # Input contract (resources, network, extra_disks)
│       ├── outputs.tf         # VM name, IP, disk paths
│       ├── providers.tf       # taliesins/hyperv required provider declaration
│       └── network_config.tftpl
└── projects/
    ├── ceph/                  # Ceph Storage Cluster Project
    │   ├── main.tf            # Instantiates module with 50GB OSD extra disks
    │   ├── servers.csv        # Ceph node specifications & disk sizes
    │   ├── ansible_inventory.tftpl
    │   ├── providers.tf
    │   ├── variables.tf
    │   └── terraform.tfvars
    └── hitachi-lab/           # Hitachi Vantara Lab Project (Standby)
        ├── main.tf            # SAM4H and Storage Emulators
        ├── servers.csv
        ├── ansible_inventory.tftpl
        ├── providers.tf
        ├── variables.tf
        └── terraform.tfvars
```

### Why a Multi-Project Structure?
1. **Zero Blast Radius**: Destroying, updating, or modifying the Ceph cluster has zero chance of altering or breaking the Hitachi lab (and vice-versa).
2. **Independent State Files**: Each project maintains its own isolated `terraform.tfstate`.
3. **Reusable Logic**: VM specifications, differencing disks, dynamic secondary disks, Cloud-Init rendering, and lifecycle policies are defined once in `modules/hyperv_vm` and inherited by all projects.

---

## 🛠 The Reusable `hyperv_vm` Module

The module (`terraform/modules/hyperv_vm`) encapsulates:
* **Differencing Disks**: Attaches a lightweight differencing VHDX linked to the base Golden Image on SCSI controller 0, location 0.
* **Dynamic Extra Disks**: Accepts an `extra_disks` parameter (`location`, `size_gb`) to create and attach raw dynamic VHDX disks (used by Ceph nodes on SCSI location 2 for OSD storage).
* **Cloud-Init (NoCloud ISO)**: Injects static IP, default gateway, DNS, hostname, and Ed25519 SSH keys into a bootable ISO attached on SCSI controller 0, location 1.
* **Hyper-V Tuning**: Uses `generation = 2`, `enable_secure_boot = "Off"`, `resource_pool_name = "Primordial"` for clean attach/detach, and `lifecycle` ignore rules to protect runtime states.

---

## ⚙️ Project Configuration (`terraform.tfvars`)

Each project contains its own `terraform.tfvars`:

```hcl
# --- Hyper-V WinRM Connection ---
# Use 127.0.0.1 in WSL mirrored networking mode
hyperv_host     = "127.0.0.1"
hyperv_user     = "maximus"
hyperv_password = "YourSecretPassword"

# --- Infrastructure Paths ---
base_image_path      = "C:\\Users\\maxim\\Documents\\Lab\\VM\\template\\OL9_5-template\\Virtual Hard Disks\\packer-ol9-build.vhdx"
vms_destination_path = "C:\\Users\\maxim\\Documents\\Lab\\VM\\Virtual Hard Disks"

# --- Cloud-Init Paths ---
iso_path_wsl     = "/mnt/c/TF_ISOs"
iso_path_windows = "C:\\TF_ISOs"
ssh_pub_key_path = "/home/maxim/.ssh/id_ed25519.pub"
```

---

## 🚀 Deploying the Ceph Cluster

### 1. Navigate to the Ceph Project
Open your WSL terminal:
```bash
cd terraform/projects/ceph
```

### 2. Initialize Providers and Modules
```bash
terraform init
```

### 3. Review Plan
> ⚠️ **Important**: Due to WinRM connection pooling limits in the Hyper-V provider, always specify `-parallelism=1` to prevent concurrent WinRM request locks.
```bash
terraform plan -parallelism=1
```

### 4. Apply Configuration
```bash
terraform apply -parallelism=1 -auto-approve
```

---

## 🚀 Deploying the Hitachi Lab (On-Demand)

To provision the SAM4H server and Storage Emulators:
```bash
cd terraform/projects/hitachi-lab
terraform init
terraform apply -parallelism=1 -auto-approve
```

---

## 📂 Output Artifacts

Upon completion of `terraform apply`, Terraform automatically generates the corresponding inventory file in `ansible/inventories/`:
* `ansible/inventories/ceph.ini` (for Ceph nodes)
* `ansible/inventories/hitachi.ini` (for Hitachi nodes)

Each VM boots in ~15–30 seconds, acquires its static IP, and is immediately accessible over SSH via your injected private key (`~/.ssh/id_ed25519`).