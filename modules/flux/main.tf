# Based on https://github.com/controlplaneio-fluxcd/flux-operator/blob/main/config/terraform/main.tf
# See also https://fluxoperator.dev/docs/guides/install/#terraform

# Create the  flux-system namespace.
resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# Create a Kubernetes secret with the Git credentials
# if a GitLab token is provided.
resource "kubernetes_secret_v1" "git_auth" {
  count      = var.git_token != "" ? 1 : 0
  depends_on = [kubernetes_namespace_v1.flux_system]

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  data = {
    username = var.git_token != "" ? var.git_username : null
    password = var.git_token != "" ? var.git_token : null
  }

  type = "Opaque"
}

# Install the Flux Operator.
resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace_v1.flux_system]

  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true
}

# Deploy the Flux instance.
resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  wait       = true

  # Configure the Flux components and kustomize patches.
  values = [
    file("${path.module}/values/components.yaml")
  ]

  # Configure the Flux distribution, cluster type and Git sync.
  set = [
    {
      name  = "instance.distribution.version"
      value = var.flux_version
    },
    {
      name  = "instance.distribution.registry"
      value = var.flux_registry
    },
    {
      name  = "instance.cluster.type"
      value = var.cluster_type
    },
    {
      name  = "instance.cluster.size"
      value = var.cluster_size
    },
    {
      name  = "instance.sync.kind"
      value = "GitRepository"
    },
    {
      name  = "instance.sync.url"
      value = var.git_url
    },
    {
      name  = "instance.sync.path"
      value = var.git_path
    },
    {
      name  = "instance.sync.ref"
      value = var.git_ref
    },
    {
      name  = "instance.sync.provider"
      value = "generic"
    },
    {
      name  = "instance.sync.pullSecret"
      value = var.git_token != "" ? "flux-system" : ""
    },
    {
      name  = "healthcheck.enabled"
      value = "true"
      type  = "auto"
    },
  ]
}
