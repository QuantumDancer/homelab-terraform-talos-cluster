# From https://github.com/controlplaneio-fluxcd/flux-operator/blob/main/config/terraform/versions.tf

terraform {
  required_version = ">= 1.7"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
  }
}
