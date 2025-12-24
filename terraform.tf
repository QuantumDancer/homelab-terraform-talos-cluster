terraform {
  required_version = "~> 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.88.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.14.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
