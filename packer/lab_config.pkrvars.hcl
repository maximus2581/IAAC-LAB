# --- Lab Network & Environment Configuration ---
golden_image_ip = "192.168.100.250"
netmask         = "255.255.255.0"
gateway         = "192.168.100.1"
dns_server      = "8.8.8.8"
vm_hostname     = "golden-image-build"
vm_timezone     = "Asia/Jerusalem"

# --- Demo Credentials (FOR LAB/PORTFOLIO USE ONLY) ---
ssh_username       = "sysadmin"
build_ssh_password = "HitachiAmazing2025"
admin_ssh_pub_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEi2rd2/FCGyncPOpsIHhh5bmFzKyEos5YBJDAaWHOF3 maxim@maximlab"

# --- Infrastructure Paths ---
iso_url          = "C:\\Users\\maxim\\Documents\\Lab\\distr\\OracleLinux-R9-U5-x86_64-dvd.iso"
iso_checksum     = "md5:aa77167bdc0042d8c6b6f11dcd1f5a96"
output_directory = "C:\\Users\\maxim\\Documents\\Lab\\VM\\template\\OL9_5-template"