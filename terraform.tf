terraform {
  required_version = "~> 1.12.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}
