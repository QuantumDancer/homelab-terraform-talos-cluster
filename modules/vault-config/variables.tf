variable "cluster_name" {
  description = "Unique name for the cluster. Used to namespace Vault auth backend path and policy/role names, so multiple clusters can share the same Vault instance."
  type        = string
}

variable "cluster_endpoint" {
  description = "Kubernetes API server URL (e.g. https://talos-prod.home.rottlr.de:6443)"
  type        = string
}

variable "cluster_ca_cert_pem" {
  description = "PEM-encoded CA certificate of the Kubernetes cluster, used by Vault to verify the API server when performing TokenReview calls."
  type        = string
}

variable "eso_namespace" {
  description = "Kubernetes namespace where External Secrets Operator is deployed."
  type        = string
  default     = "external-secrets-operator"
}

variable "vault_kv_mount" {
  description = "Path of the KV v2 secrets engine mount in Vault."
  type        = string
  default     = "secrets"
}

variable "vault_kv_secret_paths" {
  description = <<-EOT
    List of path prefixes within the KV v2 mount that ESO is allowed to read.
    For each prefix the policy grants:
      - read + list on <mount>/data/<prefix>/*
      - list on <mount>/metadata/<prefix>/*
    Example: ["idp", "platform"] grants access to secrets/data/idp/* and secrets/data/platform/*.
  EOT
  type        = list(string)
}
