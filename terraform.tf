terraform {
  required_version = "~> 1.12.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.79.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }

    flux = {
      source  = "fluxcd/flux"
      version = "1.6.4"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.1.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
