locals {
  image_id  = "${talos_image_factory_schematic.this.id}_${var.image.version}"
  image_url = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${var.image.version}/${var.image.platform}-${var.image.arch}.raw.gz"
}

resource "talos_image_factory_schematic" "this" {
  schematic = file("${path.module}/image/schematic.yaml")
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
