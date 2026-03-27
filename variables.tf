# Proxmox

variable "proxmox_endpoint" {
  type        = string
  description = "Endpoint of the Proxmox node/cluster"
}

variable "proxmox_api_token" {
  type        = string
  description = "API token for authentication to Proxmox"
  sensitive   = true
}

variable "proxmox_username" {
  type        = string
  description = "Linux user to authenticate to Proxmox via SSH"
}

variable "proxmox_ssh_private_key_location" {
  description = "Location of the private SSH key for the user specified in proxmox_username"
  type        = string
}

# Cloudflare

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}

# Vault

variable "vault_address" {
  description = "Vault API endpoint"
  type        = string
}

variable "vault_role_id" {
  description = "AppRole role ID for Terraform's Vault authentication"
  type        = string
}

variable "vault_secret_id" {
  description = "AppRole secret ID for Terraform's Vault authentication"
  type        = string
  sensitive   = true
}

# ArgoCD

variable "argocd_url" {
  description = "Public URL where ArgoCD will be accessible"
  type        = string
  default     = "https://argocd.k8s.home.rottlr.de"
}

variable "argocd_repo_url" {
  description = "Git repository URL for ArgoCD applications"
  type        = string
  default     = "https://gitlab.home.rottlr.de/idp/platform/idp-argocd-platform-apps.git"
}

variable "argocd_repo_username" {
  description = "Username for ArgoCD Git repository authentication. Optional for public repositories."
  type        = string
  default     = null
}

variable "argocd_repo_password" {
  description = "Password/token for ArgoCD Git repository authentication. Optional for public repositories."
  type        = string
  sensitive   = true
  default     = null
}

variable "argocd_gitlab_url" {
  description = "Base URL of the GitLab instance used as OIDC provider for ArgoCD SSO"
  type        = string
  default     = "https://gitlab.home.rottlr.de"
}

variable "argocd_oidc_client_id" {
  description = "GitLab OAuth2 application client ID for ArgoCD SSO"
  type        = string
}

variable "argocd_oidc_client_secret" {
  description = "GitLab OAuth2 application client secret for ArgoCD SSO"
  type        = string
  sensitive   = true
}

variable "argocd_sso_admin_groups" {
  description = "GitLab group paths to grant ArgoCD admin role"
  type        = list(string)
  default     = ["idp/platform"]
}

# Flux

variable "flux_gitlab_username" {
  description = "GitLab deploy token username for Flux to authenticate to the GitOps repository"
  type        = string
}

variable "flux_gitlab_token" {
  description = "GitLab deploy token for Flux to authenticate to the GitOps repository"
  type        = string
  sensitive   = true
}
