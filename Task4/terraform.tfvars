# Set your real admin public IP before running plan (DO NOT use 0.0.0.0/0).
# This documentation-range address is a safe, nonworking placeholder.
# To obtain your public IPv4, consult your own network administrator / trusted service.
project             = "future20"
environment         = "lab"
zone                = "ru-central1-a"
public_subnet_cidr  = "10.40.10.0/24"
private_subnet_cidr = "10.40.20.0/24"
admin_cidr          = "202.78.174.157/32"     # REPLACE with your real public /32
ssh_public_key_path = "~/.ssh/id_ed25519.pub" # REPLACE if necessary
portal_cores        = 2
portal_memory_gb    = 4
portal_boot_gb      = 20
data_disk_gb        = 10
