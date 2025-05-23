output "vm_ids" {
  description = "Map of node names to their VM IDs"
  value       = { for k, v in proxmox_virtual_environment_vm.this : k => v.vm_id }
}

output "vm_ips" {
  description = "Map of node names to their IP addresses"
  value       = { for k, v in var.nodes : k => v.ip }
}

output "cluster_name" {
  description = "Name of the Talos cluster"
  value       = var.cluster.name
}

output "talos_image_id" {
  description = "ID of the Talos image downloaded to Proxmox"
  value       = proxmox_virtual_environment_download_file.this.id
}