terraform {
  required_version = "~> 1.13.0"

  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.4"
    }

    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
