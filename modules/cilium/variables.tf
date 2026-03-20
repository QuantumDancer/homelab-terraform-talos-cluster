variable "cilium_version" {
  description = "Cilium Helm chart version"
  type        = string
}

variable "client_configuration" {
  description = "Talos client configuration, required for pre- and post-install cluster health checks"
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
  sensitive = true
}

variable "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  type        = list(string)
}

variable "worker_ips" {
  description = "IP addresses of worker nodes"
  type        = list(string)
  default     = []
}
