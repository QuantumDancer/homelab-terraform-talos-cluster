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
  version    = "1.19.1" # renovate: github-releases=cilium/cilium
  namespace  = "kube-system"

  # Talos specific settings (with KubeProxy replacement)

  set = [
    {
      name  = "kubeProxyReplacement"
      value = "true"
    },
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,,GID,SETUID}"
    },
    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = "false"
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "k8sServicePort"
      value = "7445"
    },
    # Gateway API
    {
      name  = "gatewayAPI.enabled"
      value = "true"
    },
    {
      name  = "gatewayAPI.enableAlpn"
      value = "true"
    },
    {
      name  = "gatewayAPI.enableAppProtocol"
      value = "true"
    },
    # Automatic rollouts when configmap is updated
    {
      name  = "rollOutCiliumPods"
      value = "true"
    },
    {
      name  = "operator.rollOutPods"
      value = "true"
    },
    # https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane/
    {
      name  = "bgpControlPlane.enabled"
      value = true
    },
    # Hubble
    # https://docs.cilium.io/en/stable/observability/hubble/,up/#hubble-setup
    # https://docs.cilium.io/en/stable/observability/hubble/hubble-ui/#hubble-ui
    {
      name  = "hubble.relay.enabled"
      value = true
    },
    {
      name  = "hubble.ui.enabled"
      value = true
    }
  ]

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
