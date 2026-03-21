# https://external-secrets.io/latest/provider/hashicorp-vault/#authentication
# https://developer.hashicorp.com/vault/docs/auth/kubernetes#configuring-kubernetes

locals {
  # Namespaced identifiers prevent collisions when this module is instantiated
  # for multiple clusters against the same Vault.
  # Use "-" not "/" — Vault disallows two mounts that share a path prefix,
  # so "kubernetes/talos" and "kubernetes/management" would conflict.
  auth_backend_path = "kubernetes-${var.cluster_name}"
  policy_name       = "external-secrets-operator-${var.cluster_name}"
  role_name         = "external-secrets-operator-${var.cluster_name}"
}

# Separate auth backend per cluster so each cluster's service account tokens
# are validated against the correct Kubernetes API server.
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = local.auth_backend_path
}

resource "vault_policy" "external_secrets_operator" {
  name = local.policy_name

  # KV v2 stores data and metadata at separate paths;
  # ESO needs metadata list access to discover available secret keys.
  # Paths are generated from var.vault_kv_secret_paths so the caller controls scope.
  policy = join("\n", [
    for prefix in var.vault_kv_secret_paths : <<-EOT
      path "${var.vault_kv_mount}/data/${prefix}/*" {
        capabilities = ["read", "list"]
      }

      path "${var.vault_kv_mount}/metadata/${prefix}/*" {
        capabilities = ["list"]
      }
    EOT
  ])
}

# Create the ESO namespace before ESO is deployed so Terraform can provision
# the Vault auth resources (SA, secret, RBAC) into it.
# ArgoCD later adopts this namespace when deploying the ESO Helm chart.
resource "kubernetes_namespace_v1" "external_secrets" {
  provider = kubernetes.this

  metadata {
    name = var.eso_namespace
  }
}

# Dedicated service account for Vault's TokenReview API calls.
resource "kubernetes_service_account_v1" "vault_auth" {
  provider = kubernetes.this

  metadata {
    name      = "vault-auth"
    namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
  }

  # ArgoCD injects its tracking annotation when it adopts this resource;
  # ignore it so Terraform doesn't perpetually try to remove it.
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Vault's Kubernetes auth backend requires a stable JWT for TokenReview API calls.
# A service-account-token Secret provides a non-expiring token, unlike projected
# volume tokens which Kubernetes rotates on a schedule. This is especially important
# for a homelab cluster that is shut down periodically: a rotated token would cause
# Vault's configured reviewer JWT to become invalid after the cluster restarts.
resource "kubernetes_secret_v1" "vault_auth_token" {
  provider = kubernetes.this

  metadata {
    name      = "vault-auth-token"
    namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.vault_auth.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Grant token review permissions to the vault-auth SA so Vault can verify
# the service account tokens presented by ESO during authentication.
resource "kubernetes_cluster_role_binding_v1" "vault_auth" {
  provider = kubernetes.this

  metadata {
    name = "vault-auth-delegator-${var.cluster_name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault_auth.metadata[0].name
    namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
  }
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.cluster_endpoint
  kubernetes_ca_cert = var.cluster_ca_cert_pem
  token_reviewer_jwt = kubernetes_secret_v1.vault_auth_token.data["token"]
}

# Role bound to the 'external-secrets' service account created by the ESO Helm chart.
resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  backend   = vault_auth_backend.kubernetes.path
  role_name = local.role_name

  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = [var.eso_namespace]

  # Must match the audience configured in ESO's ClusterSecretStore resource.
  audience = "vault"

  token_policies = [vault_policy.external_secrets_operator.name]

  # ESO re-authenticates to Vault from scratch on every pod restart, so these TTLs
  # govern the lifetime of a single Vault token lease between refreshes — not how
  # long ESO can go without connectivity to Vault.
  token_ttl     = 3600  # 1h — ESO refreshes at ~2/3 remaining lease
  token_max_ttl = 86400 # 24h — hard ceiling per authentication
}
