provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  ssh {
    agent       = true
    username    = var.proxmox_username
    private_key = file(var.proxmox_ssh_private_key_location)
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(module.talos.kube_config).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.talos.kube_config).clusters[0].cluster.certificate-authority-data)
  }
}
