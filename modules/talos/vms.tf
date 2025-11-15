# Main VM that runs Talos Linux
resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  name        = each.key
  description = var.cluster.name
  tags        = ["terraform", "k8s", local.cluster_name]

  node_name = each.value.proxmox_node_name
  vm_id     = each.value.vm_id

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
    file_id      = each.value.update ? proxmox_virtual_environment_download_file.update[0].id : proxmox_virtual_environment_download_file.this.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    ssd          = true
    file_format  = "raw"
    size         = each.value.main_disk_size
  }
  boot_order = ["scsi0"]

  # Attach disks from data VMs
  dynamic "disk" {
    for_each = each.value.additional_disks != null ? each.value.additional_disks : {}
    iterator = additional_disk
    content {
      datastore_id      = additional_disk.value.datastore_id
      path_in_datastore = proxmox_virtual_environment_vm.data[each.key].disk[index(keys(each.value.additional_disks), additional_disk.key)].path_in_datastore
      interface         = "scsi${additional_disk.value.scsi_id}"
      iothread          = true
      discard           = "on"
      ssd               = true
      file_format       = "raw"
      size              = additional_disk.value.size
    }
  }

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

# Data VMs to hold additional disks that should persist across VM replacements
resource "proxmox_virtual_environment_vm" "data" {
  for_each = {
    for node_name, node in var.nodes : node_name => node
    if node.additional_disks != null && length(node.additional_disks) > 0
  }

  name        = "${each.key}-data"
  description = "${var.cluster.name} - Data disks for ${each.key}"
  tags        = ["terraform", "k8s", local.cluster_name, "data-only"]

  node_name = each.value.proxmox_node_name
  vm_id     = each.value.vm_id + 1000

  # Never start these VMs, they only serve as disk containers
  started = false
  on_boot = false

  # Minimal CPU and memory
  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 128
  }

  scsi_hardware = "virtio-scsi-single"

  # Create all additional disks in the data VM
  dynamic "disk" {
    for_each = each.value.additional_disks != null ? each.value.additional_disks : {}
    content {
      datastore_id = disk.value.datastore_id
      interface    = "scsi${disk.value.scsi_id}"
      iothread     = true
      discard      = "on"
      ssd          = true
      file_format  = "raw"
      size         = disk.value.size
    }
  }

  network_device {
    bridge = var.cluster.bridge
  }

  lifecycle {
    prevent_destroy = true
  }
}
