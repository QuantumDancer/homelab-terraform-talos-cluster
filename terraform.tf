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

    flux = {
      source  = "fluxcd/flux"
      version = "1.7.4"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.6.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
