locals {
  image_id         = "${talos_image_factory_schematic.this.id}_${var.image.version}"
  image_url        = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${var.image.version}/${var.image.platform}-${var.image.arch}.raw.gz"
  cluster_name     = "${var.cluster.name}-${var.cluster.environment}"
  cluster_endpoint = "https://${var.cluster.kubernetes_api_endpoint_url}:6443"
}

