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
  kubernetes = {
    host                   = yamldecode(module.talos.kube_config).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.talos.kube_config).clusters[0].cluster.certificate-authority-data)
  }
}

provider "gitlab" {
  token    = var.gitlab_token
  base_url = "https://${var.gitlab_url}/api/v4/"
}

provider "flux" {
  kubernetes = {
    host                   = yamldecode(module.talos.kube_config).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.talos.kube_config).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.talos.kube_config).clusters[0].cluster.certificate-authority-data)
  }
  git = {
    url = "ssh://git@${var.gitlab_url}/${module.flux_gitlab.gitlab_cluster_config_project_path_with_namespace}.git"
    ssh = {
      username    = "git"
      private_key = module.flux_gitlab.private_key_pem
      known_hosts = var.gitlab_known_hosts
    }
  }
}
