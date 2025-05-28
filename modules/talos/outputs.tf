output "talos_config" {
  description = "Talos client configuration for cluster management"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration for cluster access"
  value       = var.vm_state == "running" ? talos_cluster_kubeconfig.this[0].kubeconfig_raw : null
  sensitive   = true
}
