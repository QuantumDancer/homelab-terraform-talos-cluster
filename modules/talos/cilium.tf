data "talos_cluster_health" "before_cilium" {
  client_configuration   = talos_machine_secrets.this.client_configuration
  control_plane_nodes    = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes           = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints              = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  skip_kubernetes_checks = true

  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]

  timeouts = {
    read = "10m"
  }
}

# https://www.talos.dev/v1.10/kubernetes-guides/network/deploying-cilium/#method-1-helm-install
resource "helm_release" "cilium" {
  depends_on = [
    data.talos_cluster_health.before_cilium
  ]

  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.18.1"
  namespace  = "kube-system"

  # Talos specific settings (with KubeProxy replacement)

  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }

  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }

  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }

  set {
    name  = "k8sServicePort"
    value = "7445"
  }

  # Gateway API

  set {
    name  = "gatewayAPI.enabled"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enableAlpn"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enableAppProtocol"
    value = "true"
  }

  # Automatic rollouts when configmap is updated

  set {
    name  = "rollOutCiliumPods"
    value = "true"
  }

  set {
    name  = "operator.rollOutPods"
    value = "true"
  }

  # https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane/
  set {
    name  = "bgpControlPlane.enabled"
    value = true
  }

  # Hubble
  # https://docs.cilium.io/en/stable/observability/hubble/setup/#hubble-setup
  # https://docs.cilium.io/en/stable/observability/hubble/hubble-ui/#hubble-ui

  set {
    name  = "hubble.relay.enabled"
    value = true
  }

  set {
    name  = "hubble.ui.enabled"
    value = true
  }

}

data "talos_cluster_health" "after_cilium" {
  client_configuration = talos_machine_secrets.this.client_configuration
  control_plane_nodes  = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes         = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]

  depends_on = [
    helm_release.cilium
  ]

  timeouts = {
    read = "10m"
  }
}
