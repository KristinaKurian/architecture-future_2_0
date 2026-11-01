variable "project" {
  description = "Prefix for all cloud resources; lowercase letters, digits, hyphens"
  type        = string
  default     = "future20"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project))
    error_message = "project must be 3-21 lowercase letters/digits/hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment label (this configuration is a non-production pilot)"
  type        = string
  default     = "lab"
  validation {
    condition     = contains(["lab", "dev", "stage"], var.environment)
    error_message = "Use lab, dev or stage; production requires separate security and availability design."
  }
}

variable "zone" {
  description = "Yandex Cloud availability zone supporting standard-v3"
  type        = string
  default     = "ru-central1-a"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public VM subnet (routing follows public VM one-to-one NAT)"
  default     = "10.40.10.0/24"
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 10))
    error_message = "Provide a valid CIDR."
  }
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private analytics subnet, outgoing route via NAT Gateway"
  default     = "10.40.20.0/24"
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 10))
    error_message = "Provide a valid CIDR."
  }
}

variable "admin_cidr" {
  type        = string
  description = "Administrator's real public IPv4 /32; used only for SSH to portal"
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "Provide your actual public IPv4/32; 0.0.0.0/0 is forbidden for SSH."
  }
}

variable "ssh_public_key_path" {
  type        = string
  description = "Public key file path, never use a private SSH key"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "portal_cores" {
  type    = number
  default = 2
  validation {
    condition     = contains([2, 4, 8], var.portal_cores)
    error_message = "Choose 2, 4 or 8 vCPUs."
  }
}

variable "portal_memory_gb" {
  type    = number
  default = 4
  validation {
    condition     = var.portal_memory_gb >= 2 && var.portal_memory_gb <= 32
    error_message = "portal_memory_gb must be between 2 and 32 GB."
  }
}

variable "portal_boot_gb" {
  type    = number
  default = 20
  validation {
    condition     = var.portal_boot_gb >= 20
    error_message = "Portal boot disk should be at least 20 GB."
  }
}

variable "data_disk_gb" {
  type    = number
  default = 10
  validation {
    condition     = var.data_disk_gb >= 1
    error_message = "Data disk should be at least 1 GB."
  }
}
