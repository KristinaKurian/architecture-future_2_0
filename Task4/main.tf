terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.177.0"
    }
  }
}

# Credentials, cloud and folder IDs come from YC_TOKEN / YC_CLOUD_ID / YC_FOLDER_ID.
# No secrets or access keys are written to terraform.tfvars.
provider "yandex" {
  zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ----------------- Networking (Terraform managed) -----------------
resource "yandex_vpc_network" "main" {
  name   = "${local.name_prefix}-vpc"
  labels = local.labels
}

resource "yandex_vpc_gateway" "egress" {
  name   = "${local.name_prefix}-nat-gw"
  labels = local.labels
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "${local.name_prefix}-private-rt"
  network_id = yandex_vpc_network.main.id
  labels     = local.labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress.id
  }
}

resource "yandex_vpc_subnet" "public" {
  name           = "${local.name_prefix}-public"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr]
  labels         = local.labels
}

resource "yandex_vpc_subnet" "private" {
  name           = "${local.name_prefix}-private"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private.id
  labels         = local.labels
}

# Explicit groups prevent the permissive default security group from being applied.
resource "yandex_vpc_security_group" "portal" {
  name       = "${local.name_prefix}-portal-sg"
  network_id = yandex_vpc_network.main.id
  labels     = local.labels

  ingress {
    description    = "SSH from administrator IP only"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }
  ingress {
    description    = "Future HTTPS portal (application is installed separately)"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "Updates and controlled outgoing connections"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------- Persistent disks (Terraform managed) -----------------
resource "yandex_compute_disk" "portal_boot" {
  name     = "${local.name_prefix}-portal-boot"
  zone     = var.zone
  type     = "network-hdd"
  size     = var.portal_boot_gb
  image_id = data.yandex_compute_image.ubuntu.id
  labels   = local.labels
}

resource "yandex_compute_disk" "lab_data" {
  name   = "${local.name_prefix}-data"
  zone   = var.zone
  type   = "network-ssd"
  size   = var.data_disk_gb
  labels = local.labels
}

# ----------------- Compute (Terraform managed) -----------------
# Quota-fitting lab: single VM with OS HDD and attached SSD.
# Private network and NAT gateway are provisioned as an infrastructure example,
# but no private VM is deployed within the 2-vCPU default quota.
# Public VM has 1:1 NAT. No application is installed automatically.
resource "yandex_compute_instance" "portal" {
  name                      = "${local.name_prefix}-portal"
  platform_id               = "standard-v3"
  zone                      = var.zone
  labels                    = local.labels
  allow_stopping_for_update = true

  resources {
    cores         = var.portal_cores
    memory        = var.portal_memory_gb
    core_fraction = 100
  }

  boot_disk {
    disk_id = yandex_compute_disk.portal_boot.id
  }

  secondary_disk {
    disk_id = yandex_compute_disk.lab_data.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.portal.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
  }
}

