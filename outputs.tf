output "talos_config" {
  description = "Talos client configuration for cluster management"
  value       = module.talos.talos_config
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration for cluster access"
  value       = module.talos.kube_config
  sensitive   = true
}

output "management_talos_config" {
  description = "Talos client configuration for cluster management for the management cluster"
  value       = module.management_cluster.talos_config
  sensitive   = true
}

output "management_kube_config" {
  description = "Kubernetes configuration for cluster access for the management cluster"
  value       = module.management_cluster.kube_config
  sensitive   = true
}
