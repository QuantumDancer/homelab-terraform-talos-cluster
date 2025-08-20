resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
  config_patches = [
    file("${path.module}/files/patch-controlplane-scheduling.yaml"),
    templatefile("${path.module}/templates/patch-networking.yaml.tmpl", {
      pod_cidr     = var.cluster.pod_cidr
      service_cidr = var.cluster.service_cidr
    }),
    yamlencode({
      cluster = {
        extraManifests = [
          "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/v0.9.2/deploy/standalone-install.yaml",
          "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml"
        ]
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
  config_patches = [
    templatefile("${path.module}/templates/patch-networking.yaml.tmpl", {
      pod_cidr     = var.cluster.pod_cidr
      service_cidr = var.cluster.service_cidr
    })
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    proxmox_virtual_environment_vm.this,
    cloudflare_dns_record.cluster_vip,
    cloudflare_dns_record.node
  ]
  for_each = { for k, v in var.nodes : k => v if v.machine_type == "controlplane" }

  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  config_patches = [
    templatefile("${path.module}/templates/patch-controlplane.yaml.tmpl", {
      cluster_name      = local.cluster_name
      cluster_endpoint  = var.cluster.kubernetes_api_endpoint_url
      cluster_vip       = var.cluster.kubernetes_api_vip
      node_hostname     = "${each.key}.${var.cluster.dns_domain}"
      node_ip           = each.value.ip
      gateway           = var.cluster.gateway
      dns_servers       = var.cluster.dns_servers
      proxmox_node_name = each.value.proxmox_node_name
    })
  ]

  timeouts = {
    create = "1m"
  }

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_vm.this[each.key]
    ]
  }
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    proxmox_virtual_environment_vm.this,
    cloudflare_dns_record.cluster_vip,
    cloudflare_dns_record.node
  ]
  for_each = { for k, v in var.nodes : k => v if v.machine_type == "worker" }

  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  config_patches = [
    templatefile("${path.module}/templates/patch-worker.yaml.tmpl", {
      cluster_name      = local.cluster_name
      cluster_endpoint  = var.cluster.kubernetes_api_endpoint_url
      cluster_vip       = var.cluster.kubernetes_api_vip
      node_hostname     = "${each.key}.${var.cluster.dns_domain}"
      node_ip           = each.value.ip
      gateway           = var.cluster.gateway
      dns_servers       = var.cluster.dns_servers
      proxmox_node_name = each.value.proxmox_node_name
    })
  ]

  timeouts = {
    create = "1m"
  }

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_vm.this[each.key]
    ]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
}
