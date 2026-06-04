# Phase 3: Configuration Management (Ansible)

In the final phase, we use **Ansible** to configure the baseline operating systems and deploy the proprietary Hitachi Vantara software stack (CCI, Storage Emulators and SAM4H). 

## 🚫 Critical Prerequisite: Proprietary Binaries
Due to licensing restrictions, the proprietary Hitachi Vantara installation files are **not included** in this repository. 

Before running any playbooks, you must manually obtain the following distributions and place them into their respective role `files/` directories.

Verify that your files match the default names defined in `roles/*/defaults/main.yml`:

1. **Hitachi Command Control Interface (CCI):**
   * Path: `ansible/roles/cci/files/`
   * Filename: `HS042_122.iso`
2. **Storage Emulator (IntegSim):**
   * Path: `ansible/roles/emulator/files/`
   * Filenames: `integsim-linux-10.5.3-00.tar.gz` and `install_sim.sh`
3. **SAM4H Docker Installer:**
   * Path: `ansible/roles/sam4h/files/`
   * Filename: `sam4hdockerinstaller-v2.4.2.tgz`

*(Note: If your file versions differ, update the corresponding variables in the `defaults/main.yml` files for each role).*

## 🛠 Environment Setup (`uv`)

We utilize `uv` to bootstrap a localized virtual environment for Ansible, ensuring a clean execution state without polluting your host system.

1. Navigate to the `ansible/` directory:
   ```bash
   cd ansible/
   ```
2. Initialize the uv project workspace:
   ```bash
   uv init .
   ```
3. Install Ansible and the Ansible Linter into the virtual environment:
   ```bash
   uv add ansible
   uv add ansible-lint
   ```

## 🚀 Execution Steps
The deployment is split into sequential playbooks to maintain modularity. Ensure that Terraform (Phase 2) has successfully completed and generated the inventory.ini file in this directory.

### Step 1: Base Configuration
Configure the foundational OS settings (such as setting the correct hostnames across the lab topology).
   ```bash
   uv run ansible-playbook -i inventory.ini playbook.yml
   ```

### Step 2: Deploy Storage Emulators
Install CCI and deploy the storage emulators. Serial numbers are automatically mapped to hostnames (e.g., emu-stor-01 -> 900001) as defined in the emulator role defaults.
   ```bash
   uv run ansible-playbook -i inventory.ini deploy_emulators.yml
   ```

### Step 3: Deploy SAM4H
Install CCI and deploy the SAM4H integration platform.
   ```bash
   uv run ansible-playbook -i inventory.ini deploy_sam4h.yml
   ```

## 📂 Result
Once the playbooks complete with zero failed tasks, your Hitachi Vantara Lab is fully operational.
You can now access the SAM4H web interface and begin integrating it with your freshly provisioned storage emulators.
---
