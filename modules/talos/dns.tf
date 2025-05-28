resource "cloudflare_dns_record" "cluster_vip" {
  zone_id = var.cloudflare_zone_id
  content = var.cluster.kubernetes_api_vip
  name    = var.cluster.kubernetes_api_endpoint_url
  ttl     = 1
  type    = "A"
}

resource "cloudflare_dns_record" "node" {
  for_each = var.nodes
  zone_id  = var.cloudflare_zone_id
  content  = each.value.ip
  name     = "${each.key}.${var.cluster.dns_domain}"
  ttl      = 1
  type     = "A"
}

