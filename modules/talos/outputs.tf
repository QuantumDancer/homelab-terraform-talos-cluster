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

output "client_configuration" {
  description = "Talos client configuration object, passed to the cilium module for health checks"
  value       = talos_machine_secrets.this.client_configuration
  sensitive   = true
}

output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value       = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
}
