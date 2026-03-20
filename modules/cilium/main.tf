locals {
  # Single-node clusters need only one operator replica (Helm chart default is 2)
  # The operator deployment uses podAntiAffinity based on the kubernetes.io/hostname label,
  # so for a single-node cluster, the operator deployment will be stuck with one replica instead of two
  operator_replicas = length(var.control_plane_ips) + length(var.worker_ips) > 1 ? 2 : 1
}

# Wait for Talos to be ready before installing Cilium. Kubernetes checks are
# skipped because the API server won't pass them until CNI is running.
data "talos_cluster_health" "pre_install" {
  client_configuration   = var.client_configuration
  control_plane_nodes    = var.control_plane_ips
  worker_nodes           = var.worker_ips
  endpoints              = var.control_plane_ips
  skip_kubernetes_checks = true

  timeouts = {
    read = "10m"
  }
}

# https://www.talos.dev/v1.10/kubernetes-guides/network/deploying-cilium/#method-1-helm-install
resource "helm_release" "cilium" {
  depends_on = [data.talos_cluster_health.pre_install]

  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
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
    {
      name  = "operator.replicas"
      value = local.operator_replicas
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

data "talos_cluster_health" "post_install" {
  client_configuration = var.client_configuration
  control_plane_nodes  = var.control_plane_ips
  worker_nodes         = var.worker_ips
  endpoints            = var.control_plane_ips

  depends_on = [helm_release.cilium]

  timeouts = {
    read = "10m"
  }
}
