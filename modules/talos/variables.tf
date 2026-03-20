variable "nodes" {
  description = "Node configuration of the Talos cluster"
  type = map(object({
    machine_type      = string                 # Type of the VM ("controlplane" or "worker")
    proxmox_node_name = string                 # The name of the Proxmox node to assign the VM to (overrides cluster default)
    vm_id             = optional(number)       # ID of the VM
    cpu               = optional(number, 4)    # Number of CPU cores
    memory            = optional(number, 4096) # Amount of memory in MB
    main_disk_size    = optional(number, 50)   # Size of the main disk in GB where Talos Linux is installed
    additional_disks = optional(map(object({   # Additional disk configuration
      datastore_id = string                    #   Datastore ID of the additional disk 
      scsi_id      = number                    #   SCSI ID of the additional disk. Start at 1, the main disk has index 0.
      size         = number                    #   Size of the additional disk in GB
    })))
    ip     = string                # IP Address of the VM
    update = optional(bool, false) # Set to true to update this node to the new Talos version specified in image.update_version
  }))

  validation {
    condition = alltrue([
      for node in var.nodes : contains(["controlplane", "worker"], node.machine_type)
    ])
    error_message = "The machine_type must be either 'controlplane' or 'worker'."
  }
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                            = string
    environment                     = string
    proxmox_datastore_id_vm_disk    = string                            # Proxmox datastore ID for VM disks
    proxmox_datastore_id_cloud_init = string                            # Proxmox datastore ID for cloud_init
    dns_domain                      = optional(string)                  # DNS search domain for VMs
    dns_servers                     = optional(list(string))            # DNS servers for VMs
    gateway                         = optional(string)                  # IPv4 gateway for VMs
    bridge                          = string                            # Network bridge for VMs
    talos_version                   = string                            # Version of Talos Linux
    talos_update_version            = optional(string)                  # Version of Talos Linux when updating Talos Linux
    kubernetes_version              = string                            # Version of Kubernetes
    kubernetes_api_endpoint_url     = string                            # Endpoint of the Kubernetes API
    kubernetes_api_vip              = string                            # VIP of the Kubernetes API
    pod_cidr                        = optional(string, "10.244.0.0/16") # Pod CIDR for Kubernetes cluster
    service_cidr                    = optional(string, "10.96.0.0/12")  # Service CIDR for Kubernetes cluster
    longhorn_enabled                = optional(bool, true)              # Set false to skip Longhorn kernel modules, mounts, and volume config
  })
}

variable "image" {
  description = "Configuration for the Talos image"
  type = object({
    factory_url          = optional(string, "https://factory.talos.dev") # Talos Linux Image Factory URL
    arch                 = optional(string, "amd64")                     # Image architecture
    platform             = optional(string, "nocloud")                   # Image platform
    proxmox_node_name    = string                                        # Name of the Proxmox node where the image should be stored
    proxmox_datastore_id = string                                        # Proxmox datastore ID where the image should be stored
  })
}


variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
}
