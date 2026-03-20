terraform {
  required_version = "~> 1.14.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
}
