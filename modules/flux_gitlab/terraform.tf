terraform {
  required_version = "~> 1.12.0"

  required_providers {
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
