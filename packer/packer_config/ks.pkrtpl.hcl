#version=RHEL9
text
reboot
cdrom

# Localization and Time
lang en_US.UTF-8
keyboard us
timezone ${vm_timezone} --utc
timesource --ntp-pool=2.pool.ntp.org

# BUILD NETWORK (Will be removed in the %post section)
network --bootproto=static --device=eth0 --ip=${ip_address} --netmask=${netmask} --gateway=${gateway} --nameserver=${dns_server} --activate
network --hostname=${hostname}

# System user for Ansible/Terraform management
rootpw --plaintext --allow-ssh ${build_password}
user --name=${ssh_username} --groups=wheel --plaintext --password=${build_password}

# Security (Lab environment settings)
firewall --disabled
selinux --disabled

# Disk Partitioning (Automatically occupies the 40GB allocated by Packer)
zerombr
clearpart --all --initlabel
autopart --type=lvm

# Minimal package set
%packages
@core
hyperv-daemons
cloud-init
tar
bzip2
%end

# Post-installation scripts (Cleanup)
%post --log=/var/log/ks-post.log
# Allow sudoers group (wheel) to execute sudo without a password
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel-nopasswd
chmod 0440 /etc/sudoers.d/wheel-nopasswd

# Disable network configuration via cloud-init
mkdir -p /etc/cloud/cloud.cfg.d
echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg 

# Configure cloud-init to allow SSH password authentication (temporarily for packer)
echo "ssh_pwauth: true" > /etc/cloud/cloud.cfg.d/99-packer-ssh.cfg
mkdir -p /etc/ssh/sshd_config.d
echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-packer-ssh.conf
%end