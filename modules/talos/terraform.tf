terraform {
  required_version = "~> 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.15.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }
}
