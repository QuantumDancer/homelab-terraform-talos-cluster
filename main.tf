locals {
  environment = "prod"
}

#####################################
# Managment Cluster for Cluster API #
#####################################

module "management_cluster" {
  source = "./modules/talos/"

  nodes = {
    mgt1 = {
      machine_type      = "controlplane"
      proxmox_node_name = "proxmox-01"
      vm_id             = 341
      ip                = "192.168.30.41"
      cpu               = 2
      memory            = 4096
      main_disk_size    = 32
    }
  }

  cluster = {
    name                            = "management"
    environment                     = local.environment
    proxmox_datastore_id_vm_disk    = "local-zfs"
    proxmox_datastore_id_cloud_init = "local-zfs"
    dns_domain                      = "home.rottlr.de"
    dns_servers                     = ["1.1.1.1", "1.0.0.1"]
    gateway                         = "192.168.30.1"
    bridge                          = "vmbr1"
    talos_version                   = "1.12.6" # renovate: github-releases=siderolabs/talos
    kubernetes_version              = "1.35.2" # renovate: github-releases=kubernetes/kubernetes
    kubernetes_api_endpoint_url     = "talos-mgt.home.rottlr.de"
    kubernetes_api_vip              = "192.168.30.40"
    longhorn_enabled                = false
  }

  image = {
    proxmox_node_name    = "proxmox-01"
    proxmox_datastore_id = "local"
  }

  cloudflare_zone_id = var.cloudflare_zone_id
}

module "cilium_management" {
  source = "./modules/cilium/"

  providers = {
    helm = helm.management
  }

  cilium_version       = "1.19.1" # renovate: github-releases=cilium/cilium
  client_configuration = module.management_cluster.client_configuration
  control_plane_ips    = module.management_cluster.control_plane_ips
  worker_ips           = module.management_cluster.worker_ips
}

#############################
# 3-node Talos Linux Custer #
#############################

module "talos" {
  source = "./modules/talos/"

  # Provisions a Talos Linux Kubernetes cluster on Proxmox VE
  # with custom image factory schematics and automated VM configuration

  nodes = {
    "talos1" = {
      machine_type      = "controlplane"
      proxmox_node_name = "proxmox-01"
      vm_id             = 351
      ip                = "192.168.30.51"
      cpu               = 8
      memory            = 10240
      additional_disks = {
        "longhorn" = {
          datastore_id = "longhorn"
          size         = 100
          scsi_id      = 1
        }
      }
      update = false
    }
    "talos2" = {
      machine_type      = "controlplane"
      proxmox_node_name = "proxmox-01"
      vm_id             = 352
      ip                = "192.168.30.52"
      cpu               = 8
      memory            = 10240
      additional_disks = {
        "longhorn" = {
          datastore_id = "longhorn"
          size         = 100
          scsi_id      = 1
        }
      }
      update = false
    }
    "talos3" = {
      machine_type      = "controlplane"
      proxmox_node_name = "proxmox-01"
      vm_id             = 353
      ip                = "192.168.30.53"
      cpu               = 8
      memory            = 10240
      additional_disks = {
        "longhorn" = {
          datastore_id = "longhorn"
          size         = 100
          scsi_id      = 1
        }
      }
      update = false
    }

  }

  cluster = {
    name                            = "talos"
    environment                     = local.environment
    proxmox_datastore_id_vm_disk    = "local-zfs"
    proxmox_datastore_id_cloud_init = "local-zfs"
    dns_domain                      = "home.rottlr.de"
    dns_servers                     = ["1.1.1.1", "1.0.0.1"]
    gateway                         = "192.168.30.1"
    bridge                          = "vmbr1"
    talos_version                   = "1.12.6"
    talos_update_version            = "1.12.6" # renovate: github-releases=siderolabs/talos
    kubernetes_version              = "1.35.2" # renovate: github-releases=kubernetes/kubernetes
    kubernetes_api_endpoint_url     = "talos-prod.home.rottlr.de"
    kubernetes_api_vip              = "192.168.30.50"
  }

  image = {
    proxmox_node_name    = "proxmox-01"
    proxmox_datastore_id = "local"
  }


  cloudflare_zone_id = var.cloudflare_zone_id
}

module "cilium_talos" {
  source = "./modules/cilium/"
  # Default helm provider targets this cluster

  cilium_version       = "1.19.1" # renovate: github-releases=cilium/cilium
  client_configuration = module.talos.client_configuration
  control_plane_ips    = module.talos.control_plane_ips
  worker_ips           = module.talos.worker_ips
}

module "argocd" {
  source = "./modules/argocd/"

  argocd_url               = var.argocd_url
  gitlab_url               = var.argocd_gitlab_url
  oidc_client_id           = var.argocd_oidc_client_id
  oidc_client_secret       = var.argocd_oidc_client_secret
  sso_admin_groups         = var.argocd_sso_admin_groups
  repo_url                 = var.argocd_repo_url
  repo_username            = var.argocd_repo_username
  repo_password            = var.argocd_repo_password
  root_app_path            = "apps"
  root_app_target_revision = "development"

  # ArgoCD requires a functional CNI before it can schedule pods
  depends_on = [module.cilium_talos]
}
