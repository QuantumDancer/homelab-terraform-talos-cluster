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
