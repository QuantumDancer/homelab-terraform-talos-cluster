# https://github.com/fluxcd/terraform-provider-flux/blob/main/examples/gitlab-via-ssh/main.tf

data "gitlab_group" "this" {
  full_path = var.gitlab_group_path
}

resource "gitlab_project" "cluster_config" {
  name                   = var.gitlab_cluster_config_project
  namespace_id           = data.gitlab_group.this.id
  description            = "Cluster configuration via FluxCD"
  visibility_level       = "internal"
  initialize_with_readme = true # This is extremely important as Flux expects an initialised repository
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "gitlab_deploy_key" "this" {
  project  = gitlab_project.cluster_config.path_with_namespace
  title    = "Flux"
  key      = tls_private_key.flux.public_key_openssh
  can_push = true
}

resource "flux_bootstrap_git" "this" {
  depends_on = [gitlab_deploy_key.this]

  embedded_manifests = true
  path               = "clusters/${var.environment}"
}
