# Hitachi Vantara Lab Automation (IaC)

This repository contains an Infrastructure as Code (IaC) solution for the fully automated provisioning and configuration of a Hitachi Vantara lab environment, including Storage Emulators and the SAM4H.

## ⚠️ Security Context: Lab Environment Provisioning
This repository is explicitly designed for provisioning isolated **Lab and Testing Environments**. 
To ensure a seamless, out-of-the-box deployment of the lab topology without manual credential management, **default passwords and non-production SSH keys are intentionally committed to this repository** (e.g., inside `lab_config.pkrvars.hcl`). 

*In a real-world production deployment, committing secrets is strictly prohibited. These values must be ignored via `.gitignore` and injected dynamically via CI/CD pipeline variables or a Secrets Manager (e.g., HashiCorp Vault).*

## 📐 Architecture Overview
The deployment process is strictly divided into three isolated stages:

1. **Golden Image Creation:** Building a standardized, sysprepped OS template using HashiCorp Packer and dynamic Kickstart templates.
2. **Infrastructure Provisioning:** Deploying and networking virtual machines on Microsoft Hyper-V.
3. **Configuration Management:** Installing and configuring software via Ansible.

## 🚫 Proprietary Software Notice
Due to licensing restrictions, **no proprietary binaries or vendor ISOs are stored in this Git repository**. 
Before running the configuration playbooks, you must manually obtain the required distributions and place them into the designated directories. See the [Ansible Configuration Guide](docs/03_ansible_config.md) for detailed paths.

## 🚀 Quick Start & Documentation
Please follow the deployment phases in strict order:

### [Phase 1: Golden Image Preparation](docs/01_golden_image.md)
Instructions on how to build the base Linux template (Oracle Linux 9) using Packer. Features completely automated provisioning, in-memory Kickstart rendering, SSH key injection, and cloud-init preparation.

### [Phase 2: Hyper-V VM Deployment](docs/02_hyperv_deployment.md)
Guide on using Terraform to clone the Golden Image via Differencing Disks and dynamically provision the lab topology (SAM4H node, Emulator nodes) with Cloud-Init (NoCloud) configurations.

### [Phase 3: Ansible Configuration](docs/03_ansible_config.md)
Details on how to execute the Ansible playbooks to deploy Hitachi CCI, Storage Emulators, and SAM4H.

---
