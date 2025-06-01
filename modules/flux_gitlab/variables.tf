variable "gitlab_group_path" {
  description = "Full path of the group in GitLab where the projects should be created"
  type        = string
}

variable "gitlab_cluster_config_project" {
  description = "Name of the GitLab project that contains the cluster configuration"
  type        = string
}

variable "environment" {
  description = "Environment of the cluster"
  type        = string
  default     = "prod"
}
