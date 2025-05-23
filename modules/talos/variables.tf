variable "nodes" {
  description = "Node configuration of the Talos cluster"
  type = map(object({
    machine_type      = string                 # Type of the VM ("control-plane" or "worker")
    proxmox_node_name = string                 # The name of the Proxmox node to assign the VM to (overrides cluster default)
    vm_id             = optional(number)       # ID of the VM
    cpu               = optional(number, 4)    # Number of CPU cores
    memory            = optional(number, 4096) # Amount of memory in MB
    main_disk_size    = optional(number, 50)   # Size of the main disk in GB where Talos Linux is installed
    ip                = string                 # IP Address of the VM
  }))

  validation {
    condition = alltrue([
      for node in var.nodes : contains(["control-plane", "worker"], node.machine_type)
    ])
    error_message = "The machine_type must be either 'control-plane' or 'worker'."
  }
}

variable "cluster" {
  description = "Cluster configuration"
  type = object({
    name                            = string
    environment                     = string
    proxmox_datastore_id_vm_disk    = string                 # Proxmox datastore ID for VM disks
    proxmox_datastore_id_cloud_init = string                 # Proxmox datastore ID for cloud_init
    dns_domain                      = optional(string)       # DNS search domain for VMs
    dns_servers                     = optional(list(string)) # DNS servers for VMs
    gateway                         = optional(string)       # IPv4 gateway for VMs
    bridge                          = string                 # Network bridge for VMs
  })
}

variable "image" {
  description = "Configuration for the Talos image"
  type = object({
    version              = string                                        # Version of the Talos image
    factory_url          = optional(string, "https://factory.talos.dev") # Talos Linux Image Factory URL
    arch                 = optional(string, "amd64")                     # Image architecture
    platform             = optional(string, "nocloud")                   # Image platform
    proxmox_node_name    = string                                        # Name of the Proxmox node where the image should be stored
    proxmox_datastore_id = string                                        # Proxmox datastore ID where the image should be stored
  })
}
