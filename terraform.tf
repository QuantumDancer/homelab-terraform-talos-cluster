terraform {
  required_version = "~> 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.96.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.17.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}
