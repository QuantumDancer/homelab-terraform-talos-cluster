locals {
  namespace = "argocd"
}

resource "helm_release" "argocd" {
  upgrade_install  = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.2.1" # renovate: github-releases=argoproj/argo-cd
  namespace        = local.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/files/argocd-values.yaml.tftpl", {
      argocd_url = var.argocd_url
    })
  ]
}

resource "kubernetes_secret_v1" "repo_credentials" {
  count = var.repo_password != null ? 1 : 0

  depends_on = [helm_release.argocd]

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

resource "kubernetes_manifest" "root_app" {
  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.repo_credentials
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-root-app"
      namespace = local.namespace
    }
    spec = {
      project = "default"

      source = {
        repoURL        = var.repo_url
        targetRevision = var.root_app_target_revision
        path           = var.root_app_path
        helm = {
          releaseName = "platform-apps"
          parameters = [
            {
              name  = "environment"
              value = "homelab"
            },
            {
              name  = "longhorn.enabled"
              value = "true"
            }
          ]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = local.namespace
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }
}
