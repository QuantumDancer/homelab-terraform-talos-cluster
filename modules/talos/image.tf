resource "talos_image_factory_schematic" "this" {
  schematic = file("${path.module}/files/image-schematic.yaml")
}

resource "proxmox_virtual_environment_download_file" "this" {
  content_type            = "iso"
  datastore_id            = var.image.proxmox_datastore_id
  file_name               = "talos-${local.image_id}-${var.image.platform}-${var.image.arch}.img"
  node_name               = var.image.proxmox_node_name
  url                     = local.image_url
  decompression_algorithm = "gz"
  overwrite               = false
}
