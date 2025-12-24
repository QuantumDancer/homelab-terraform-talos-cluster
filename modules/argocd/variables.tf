variable "argocd_url" {
  description = "Public URL where ArgoCD will be accessible"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
}

variable "repo_username" {
  description = "Username for Git repository authentication"
  type        = string
}

variable "repo_password" {
  description = "Password/token for Git repository authentication"
  type        = string
  sensitive   = true
}

variable "root_app_path" {
  description = "Path in repository containing the root application"
  type        = string
  default     = "apps"
}

variable "root_app_target_revision" {
  description = "Git branch/tag/commit for root application"
  type        = string
  default     = "main"
}
