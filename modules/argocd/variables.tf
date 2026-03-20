variable "argocd_url" {
  description = "Public URL where ArgoCD will be accessible"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
}

variable "repo_username" {
  description = "Username for Git repository authentication. Optional for public repositories."
  type        = string
  default     = null
}

variable "repo_password" {
  description = "Password/token for Git repository authentication. Optional for public repositories."
  type        = string
  sensitive   = true
  default     = null
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

variable "environment" {
  description = "Environment name, used to select the Helm values overlay (environments/<name>.yaml)"
  type        = string
  default     = "homelab"
}

variable "gitlab_url" {
  description = "Base URL of the self-hosted GitLab instance used as OIDC provider"
  type        = string
}

variable "oidc_client_id" {
  description = "GitLab OAuth2 application client ID for ArgoCD SSO"
  type        = string
}

variable "oidc_client_secret" {
  description = "GitLab OAuth2 application client secret for ArgoCD SSO"
  type        = string
  sensitive   = true
}

variable "sso_admin_groups" {
  description = "GitLab group paths (full path, e.g. 'myorg/admins') to grant ArgoCD admin role"
  type        = list(string)
  default     = []
}
