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

resource "kubernetes_manifest" "platform_project" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "platform"
      namespace = local.namespace
    }
    spec = {
      description = "Platform infrastructure"
      sourceRepos = ["*"]
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      # Platform apps manage cluster-level resources (CRDs, ClusterRoles, etc.)
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "root_app" {
  depends_on = [
    kubernetes_manifest.platform_project,
    kubernetes_secret_v1.repo_credentials,
  ]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-root-app"
      namespace = local.namespace
    }
    spec = {
      project = "platform"

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
            },
            {
              name  = "networkingConfig.enabled"
              value = "true"
            },
            {
              name  = "gatewayApiCrds.enabled"
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
