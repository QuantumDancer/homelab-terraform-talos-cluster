terraform {
  required_version = "~> 1.14.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
      # configuration_aliases lets callers pass a per-cluster kubernetes provider,
      # enabling this module to be instantiated once per cluster without provider conflicts.
      configuration_aliases = [kubernetes.this]
    }
  }
}
