# Phase 1: Golden Image Creation (Oracle Linux 9)

A **Golden Image** is a baseline, pre-configured virtual machine template. Instead of manually installing Linux for every new SAM4H server or emulator, we build a "clean" sysprepped image once. 

For automated image creation, we use **HashiCorp Packer** in combination with the **Hyper-V** hypervisor and a dynamic **Kickstart** template (`ks.pkrtpl.hcl`).

## 🛠 Under the Hood: What Packer Does
The process is fully automated, requires zero manual input, and takes about 10-15 minutes:
1. Packer creates a temporary VM in Hyper-V (Generation 2).
2. It reads your network configurations and secrets from `lab_config.pkrvars.hcl` and dynamically renders the `ks.pkrtpl.hcl` Kickstart file.
3. It mounts the Oracle Linux 9 installation ISO and injects the rendered Kickstart file as a virtual CD-ROM.
4. The OS installs automatically (provisions a 40GB LVM, sets static IPs, disables SELinux/Firewall for the lab, and installs a minimal package set).
5. Installs `hyperv-daemons` (for host integration) and `cloud-init` (for configuring future clones).
6. Packer logs in via SSH, injects the public key for the `sysadmin` user, and performs a "sysprep" — removing unique identifiers (`machine-id`, MAC addresses, SSH host keys) so the image can be safely cloned.
7. The VM is powered off and exported to the finalized template folder.

## 📋 Prerequisites
Before running the build, ensure the following conditions are met on the host machine:
1. **Hyper-V** is installed and configured.
2. A virtual switch named **`LabSwitch`** is created in Hyper-V.
3. **Packer** is installed and added to your system PATH.
4. The Oracle Linux 9 installation image is downloaded. *(Ensure the `iso_url` path in your `lab_config.pkrvars.hcl` points to your local file).*
5. **ISO Creation Tool (Windows Specific):** Packer requires a CLI tool to dynamically generate the virtual CD-ROM. You must install `cdrtools` (which includes `mkisofs.exe`) on your Windows host.
   * Via Scoop: `scoop install cdrtools`
   * Via Chocolatey: `choco install cdrtools -y`
   *(Note: If you run Packer via WSL, ensure this tool is installed in Windows so `packer.exe` can access it via the PATH variable).

## ⚙️ Configuration
All environment-specific variables (IP addresses, paths, and passwords) are isolated in a single file for easy portability:
* Edit `lab_config.pkrvars.hcl` in the project root to match your lab environment before running the build.

## 🚀 Build Execution
> **⚠️ Important Note for WSL Users:** Since Hyper-V is a Windows feature, we must use the Windows version of Packer. When running commands from inside Windows Subsystem for Linux (WSL), you must explicitly append `.exe` to invoke the Windows binary via WSL Interop.

1. Open a terminal (PowerShell, CMD, or WSL) and navigate to the project's root directory.
2. Initialize Packer plugins (this only needs to be run once):
   ```bash
   packer.exe init hyperv-ol9.pkr.hcl
   ```
3. Start the build process, passing the variables file and forcing the overwrite of any old templates:
   ```bash
   packer.exe build -force -var-file="lab_config.pkrvars.hcl" hyperv-ol9.pkr.hcl
   ```

## 🔐 Default Credentials (Baked into the Image)
* User: sysadmin (added to the wheel group with passwordless sudo privileges).

* Password: (Defined in your pkrvars file; remote password login is disabled at the end of the build).

* SSH Key: An Ed25519 public key (from lab_config.pkrvars.hcl) is baked in for passwordless Ansible access.

## 📂 Result
After successful completion, Packer will delete the temporary build machine from Hyper-V, and the finalized template will be exported to the directory specified in your output_directory variable.

This template is fully ready for rapid cloning in the next phase!