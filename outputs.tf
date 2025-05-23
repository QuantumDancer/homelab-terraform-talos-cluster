output "cluster_name" {
  description = "Name of the deployed Talos cluster"
  value       = module.talos.cluster_name
}

output "node_ips" {
  description = "IP addresses of all cluster nodes"
  value       = module.talos.vm_ips
}

output "vm_ids" {
  description = "Proxmox VM IDs for all cluster nodes"
  value       = module.talos.vm_ids
}
