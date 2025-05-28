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

variable "vm_state" {
  description = "Desired state of the VMs ('running' or 'stopped')"
  type        = string
  default     = "running"

  validation {
    condition     = contains(["running", "stopped"], var.vm_state)
    error_message = "vm_state must be either 'running' or 'stopped'."
  }
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}
