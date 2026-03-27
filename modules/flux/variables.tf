# Based on https://github.com/controlplaneio-fluxcd/flux-operator/blob/main/config/terraform/variables.tf

variable "flux_version" {
  description = "Flux version semver range"
  type        = string
  default     = "2.x"
}

variable "flux_registry" {
  description = "Flux distribution registry"
  type        = string
  default     = "ghcr.io/fluxcd"
}

variable "cluster_type" {
  description = "Cluster type, e.g. kubernetes, openshift, azure, aws, gcp"
  type        = string
  default     = "kubernetes"
}

variable "cluster_size" {
  description = "Cluster size, e.g. small, medium, large"
  type        = string
  default     = "medium"
}

variable "git_username" {
  description = "Git username for repository authentication (e.g. the deploy token username)"
  type        = string
  default     = ""
}

variable "git_token" {
  description = "Git token for repository authentication"
  sensitive   = true
  type        = string
  default     = ""
}

variable "git_url" {
  description = "Git repository URL"
  type        = string
  nullable    = false
}

variable "git_path" {
  description = "Path to the cluster manifests in the Git repository"
  type        = string
  nullable    = false
}

variable "git_ref" {
  description = "Git branch or tag in the format refs/heads/main or refs/tags/v1.0.0"
  type        = string
  default     = "refs/heads/main"
}
