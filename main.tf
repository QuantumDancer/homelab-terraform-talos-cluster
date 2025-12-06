locals {
  environment = "prod"
}

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
      memory            = 10240
      additional_disks = {
        "longhorn" = {
          datastore_id = "longhorn"
          size         = 100
          scsi_id      = 1
        }
      }
      update = true
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
    talos_version                   = "1.11.5"
    talos_update_version            = "1.11.5" # renovate: github-releases=siderolabs/talos
    kubernetes_version              = "1.33.4" # renovate: github-releases=kubernetes/kubernetes
    kubernetes_api_endpoint_url     = "talos-prod.home.rottlr.de"
    kubernetes_api_vip              = "192.168.30.50"
  }

  image = {
    proxmox_node_name    = "proxmox-01"
    proxmox_datastore_id = "local"
  }


  cloudflare_zone_id = var.cloudflare_zone_id
}

module "flux_gitlab" {
  source = "./modules/flux_gitlab/"

  gitlab_group_path             = "homelab"
  gitlab_cluster_config_project = "flux-cluster-config"
  environment                   = local.environment
}
