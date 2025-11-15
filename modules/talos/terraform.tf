terraform {
  required_version = "~> 1.13.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.0"
    }
  }
}
