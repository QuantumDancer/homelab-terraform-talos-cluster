resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  name        = each.key
  description = var.cluster.name
  tags        = ["terraform", "k8s", local.cluster_name]

  node_name = each.value.proxmox_node_name
  vm_id     = each.value.vm_id
  started   = var.vm_state == "running"

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.cluster.proxmox_datastore_id_vm_disk
    file_id      = proxmox_virtual_environment_download_file.this.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = each.value.main_disk_size
  }
  boot_order = ["scsi0"]

  network_device {
    bridge = var.cluster.bridge
  }

  initialization {
    datastore_id = var.cluster.proxmox_datastore_id_cloud_init

    dns {
      domain  = var.cluster.dns_domain
      servers = var.cluster.dns_servers
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.cluster.gateway
      }
    }
  }

}
