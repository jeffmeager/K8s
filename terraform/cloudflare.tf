data "cloudflare_zone" "your_domain" {
  name = "meager.net"
}

data "kubernetes_service" "webapp_service" {
  metadata {
    name      = "webapp-service"
    namespace = "default"
  }

  depends_on = [null_resource.wait_for_cluster_ready, 
                aws_instance.mongodb_instance]
}

resource "cloudflare_record" "mongodb_a_record" {
  zone_id = data.cloudflare_zone.your_domain.id
  name    = "mongodb"
  type    = "A"

  content = try(aws_instance.mongodb_instance.public_ip, "127.0.0.1")

  ttl     = 300
  proxied = false
}

resource "cloudflare_record" "webapp_cname" {
  zone_id = data.cloudflare_zone.your_domain.id
  name    = "webapp"
  type    = "CNAME"

  value = try(
    data.kubernetes_service.webapp_service.status[0].load_balancer[0].ingress[0].hostname,
    "placeholder.meager.net"
  )

  ttl     = 300
  proxied = false
}

