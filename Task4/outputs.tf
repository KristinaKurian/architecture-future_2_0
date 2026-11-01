output "network_id" {
  description = "Terraform-managed VPC"
  value       = yandex_vpc_network.main.id
}

output "subnet_ids" {
  description = "Public and private subnet IDs"
  value = {
    public  = yandex_vpc_subnet.public.id
    private = yandex_vpc_subnet.private.id
  }
}

output "nat_gateway_id" {
  description = "NAT Gateway reserved for future private VM egress"
  value       = yandex_vpc_gateway.egress.id
}

output "portal_public_ip" {
  description = "Public IP of lab portal VM (application not yet installed)"
  value       = yandex_compute_instance.portal.network_interface[0].nat_ip_address
}

output "portal_private_ip" {
  value = yandex_compute_instance.portal.network_interface[0].ip_address
}

output "data_disk_id" {
  description = "10 GB SSD attached to lab VM; format and mount separately"
  value       = yandex_compute_disk.lab_data.id
}

output "vm_name" {
  value = yandex_compute_instance.portal.name
}
