locals {
  image_id         = "${talos_image_factory_schematic.this.id}_${var.cluster.talos_version}"
  image_url        = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${var.cluster.talos_version}/${var.image.platform}-${var.image.arch}.raw.gz"
  update_required  = anytrue([for node in var.nodes : node.update])
  update_image_id  = local.update_required ? "${talos_image_factory_schematic.update[0].id}_${var.cluster.talos_update_version}" : local.image_id
  update_image_url = local.update_required ? "${var.image.factory_url}/image/${talos_image_factory_schematic.update[0].id}/${var.cluster.talos_update_version}/${var.image.platform}-${var.image.arch}.raw.gz" : local.image_url
  cluster_name     = "${var.cluster.name}-${var.cluster.environment}"
  cluster_endpoint = "https://${var.cluster.kubernetes_api_endpoint_url}:6443"
}

