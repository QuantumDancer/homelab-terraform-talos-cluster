resource "talos_image_factory_schematic" "this" {
  schematic = file("${path.module}/files/image-schematic.yaml")
}

# Use a different file when the image schematic should be changed
resource "talos_image_factory_schematic" "update" {
  count = local.update_required ? 1 : 0

  schematic = file("${path.module}/files/image-schematic-update.yaml")
}

resource "proxmox_virtual_environment_download_file" "this" {
  content_type            = "iso"
  datastore_id            = var.image.proxmox_datastore_id
  file_name               = "talos-${local.cluster_name}-${local.image_id}-${var.image.platform}-${var.image.arch}_current.img"
  node_name               = var.image.proxmox_node_name
  url                     = local.image_url
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "proxmox_virtual_environment_download_file" "update" {
  count = local.update_required ? 1 : 0

  content_type            = "iso"
  datastore_id            = var.image.proxmox_datastore_id
  file_name               = "talos-${local.cluster_name}-${local.update_image_id}-${var.image.platform}-${var.image.arch}_update.img"
  node_name               = var.image.proxmox_node_name
  url                     = local.update_image_url
  decompression_algorithm = "gz"
  overwrite               = false
}
