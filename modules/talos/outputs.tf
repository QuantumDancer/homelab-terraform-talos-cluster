output "talos_config" {
  description = "Talos client configuration for cluster management"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes configuration for cluster access"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}
