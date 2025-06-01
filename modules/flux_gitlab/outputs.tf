output "gitlab_cluster_config_project_path_with_namespace" {
  description = "Full path to the GitLab project that holds the cluster configuration"
  value       = gitlab_project.cluster_config.path_with_namespace
}

output "private_key_pem" {
  description = "Private key of the GitLab deploy key in PEM format"
  value       = tls_private_key.flux.private_key_pem
  sensitive   = true
}
