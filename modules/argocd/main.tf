locals {
  namespace = "argocd"
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret_v1" "oidc_gitlab" {
  depends_on = [kubernetes_namespace_v1.argocd]

  metadata {
    name      = "argocd-oidc-gitlab"
    namespace = local.namespace
    labels = {
      # ArgoCD watches secrets with this label for config reload
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    clientSecret = var.oidc_client_secret
  }
}

resource "helm_release" "argocd" {
  # OIDC secret must exist before ArgoCD starts so the reference is resolved on first boot
  depends_on = [kubernetes_secret_v1.oidc_gitlab]

  upgrade_install = true
  name            = "argocd"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  version         = "9.4.3" # renovate: github-releases=argoproj/argo-cd
  namespace       = local.namespace
  # Namespace is managed by kubernetes_namespace_v1.argocd
  create_namespace = false

  values = [
    templatefile("${path.module}/files/argocd-values.yaml.tftpl", {
      argocd_url       = var.argocd_url
      gitlab_url       = var.gitlab_url
      oidc_client_id   = var.oidc_client_id
      sso_admin_groups = var.sso_admin_groups
    })
  ]
}

resource "kubernetes_secret_v1" "repo_credentials" {
  count = var.repo_password != null ? 1 : 0

  depends_on = [kubernetes_namespace_v1.argocd]

  metadata {
    name      = "git-repo-credentials"
    namespace = local.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.repo_url
    username = var.repo_username
    password = var.repo_password
  }
}

# Wrapping AppProject and Application in Helm releases avoids plan failures on a fresh
# cluster where ArgoCD CRDs do not exist yet. Helm defers CRD validation until
# apply time, whereas kubernetes_manifest validates against the live API at plan.

# The AppProject must exist before the Application that references it, and must
# outlive it on destroy. This ensures the "platform" project is still present
# while ArgoCD processes the Application's cascade-delete finalizer,
# preventing "project not found" errors during deletion.
resource "helm_release" "root_app_project" {
  upgrade_install = true
  name            = "platform-root-app-project"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argocd-apps"
  namespace       = local.namespace

  values = [
    templatefile("${path.module}/files/root-app-project-values.yaml.tftpl", {
      namespace = local.namespace
    })
  ]

  depends_on = [helm_release.argocd]
}

resource "helm_release" "root_app" {
  upgrade_install = true
  name            = "platform-root-app"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argocd-apps"
  namespace       = local.namespace

  values = [
    templatefile("${path.module}/files/root-app-values.yaml.tftpl", {
      namespace       = local.namespace
      repo_url        = var.repo_url
      target_revision = var.root_app_target_revision
      path            = var.root_app_path
      environment     = var.environment
    })
  ]

  depends_on = [
    helm_release.root_app_project,
    kubernetes_secret_v1.repo_credentials,
  ]
}
