# Infrastructure Automation Lab (IaC)

This repository contains an Infrastructure as Code (IaC) and Configuration Management solution for provisioning and orchestrating virtualized labs on Microsoft Hyper-V using **Terraform** and **Ansible**.

It supports multiple isolated project topologies—including a **Ceph Storage Cluster** and a **Hitachi Vantara Lab** (SAM4H and Storage Emulators)—built on standardized Linux templates.

---

## 📜 Project Evolution & Architecture Milestones

To see how this infrastructure evolved from a basic setup to an enterprise-grade modular architecture, you can browse the corresponding milestone branches:

* [**v1.0 (Monolithic Architecture)**](https://github.com/maximus2581/IAAC-LAB/tree/v1-monolithic) — Initial proof-of-concept: single-state `main.tf`, flat `servers.csv`, and shared `inventory.ini`.
* [**v2.0 (Modular Multi-Project Architecture)**](https://github.com/maximus2581/IAAC-LAB/tree/main) — Production-ready refactor: reusable Hyper-V module (`modules/hyperv_vm`), decoupled clusters (`projects/ceph` with raw OSD disks, `projects/hitachi-lab`), isolated blast radius, independent state management, and organized Ansible directories.

---

## ⚠️ Security Context: Lab Environment Provisioning
This repository is explicitly designed for provisioning isolated **Lab and Testing Environments**. 
To ensure a seamless, out-of-the-box deployment of the lab topology without manual credential management, **default passwords and non-production SSH keys are intentionally committed to this repository** (e.g., inside `lab_config.pkrvars.hcl` and `terraform.tfvars`). 

*In a real-world production deployment, committing secrets is strictly prohibited. These values must be ignored via `.gitignore` and injected dynamically via CI/CD pipeline variables or a Secrets Manager (e.g., HashiCorp Vault).*

---

## 📐 Architecture Overview

The automation framework follows a 3-stage lifecycle built on modular best practices:

```
                      ┌──────────────────────────────────────────────┐
                      │    Stage 1: Golden Image (Packer)            │
                      │    - Oracle Linux 9 Generation 2 VHDX        │
                      │    - Automated Kickstart, Cloud-Init, Sysprep│
                      └──────────────────────┬───────────────────────┘
                                             │ Master VHDX
                                             ▼
                      ┌──────────────────────────────────────────────┐
                      │    Stage 2: Infrastructure (Terraform)       │
                      │    - Reusable Module: `modules/hyperv_vm`    │
                      │    - Project: `projects/ceph` (OSD Disks)    │
                      │    - Project: `projects/hitachi-lab`         │
                      │    - Generates dynamic Ansible inventories   │
                      └──────────────────────┬───────────────────────┘
                                             │ Dynamic Inventory
                                             ▼
                      ┌──────────────────────────────────────────────┐
                      │    Stage 3: Configuration (Ansible)          │
                      │    - Shared roles in `ansible/roles/`        │
                      │    - Isolated inventories in `inventories/`  │
                      │    - Project playbooks in `playbooks/`       │
                      └──────────────────────────────────────────────┘
```

### 1. Golden Image Creation (Packer)
Builds a standardized, sysprepped OS template using HashiCorp Packer and dynamic Kickstart templates.

### 2. Multi-Project Infrastructure (Terraform)
Infrastructure code is decoupled into independent projects and a shared module:
* **`terraform/modules/hyperv_vm`**: Reusable building block managing Differencing VHDX creation, optional dynamic secondary disks (e.g. Ceph raw OSDs), Cloud-Init NoCloud ISO generation, and Gen2 VM provisioning with WinRM serialization.
* **`terraform/projects/ceph`**: Dedicated Ceph cluster project (3 nodes, 4 vCPU, 8GB RAM, plus 50GB raw disk attached on SCSI location 2 for OSDs). Automatically renders `ansible/inventories/ceph.ini`.
* **`terraform/projects/hitachi-lab`**: Standby Hitachi environment (`sam4h-srv`, `emu-stor-01`, `emu-stor-02`). Automatically renders `ansible/inventories/hitachi.ini`.

### 3. Decoupled Configuration Management (Ansible)
* **Inventories (`ansible/inventories/`)**: Project-specific inventory files generated directly by Terraform.
* **Playbooks (`ansible/playbooks/`)**: Targeted playbooks for foundational provisioning and project workloads.
* **Shared Roles (`ansible/roles/`)**: Centralized repository of automation roles (`ceph`, `sam4h`, `emulator`, `cci`).

---

## 🚫 Proprietary Software Notice
Due to licensing restrictions, **no proprietary binaries or vendor ISOs are stored in this Git repository**. 
Before running the Hitachi configuration playbooks, you must manually obtain the required distributions and place them into the designated role directories. See the [Ansible Configuration Guide](docs/03_ansible_config.md) for detailed paths.

---

## 🚀 Quick Start & Documentation

Follow the deployment phases:

1. **[Phase 1: Golden Image Preparation](docs/01_golden_image.md)**: Build the base Linux template (Oracle Linux 9) with Packer.
2. **[Phase 2: Hyper-V VM Deployment](docs/02_hyperv_deployment.md)**: Deploy isolated cluster projects using Terraform and the reusable VM module.
3. **[Phase 3: Ansible Configuration](docs/03_ansible_config.md)**: Run playbooks with `uv` against project-specific inventories.
