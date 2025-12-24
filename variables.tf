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

# GitLab

variable "gitlab_token" {
  description = "The GitLab token to use for authenticating against the GitLab API"
  sensitive   = true
  type        = string
}

variable "gitlab_url" {
  description = "The base URL for the GitLab intance to use."
  type        = string
}

variable "gitlab_ssh_port" {
  description = "The port used by SSH to clone from GitLab"
  type        = number
  default     = 22
}


variable "gitlab_known_hosts" {
  description = "SSH known hosts for GitLab instance (obtain via ssh-keyscan)"
  type        = string
  sensitive   = false
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
  description = "Username for ArgoCD Git repository authentication"
  type        = string
  default     = "argocd-homelab"
}

variable "argocd_repo_password" {
  description = "Password/token for ArgoCD Git repository authentication"
  type        = string
  sensitive   = true
}
