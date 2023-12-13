locals {
    #depends_on = [ data.kubernetes_service.wordpress ]

    # Hashed data to sign the DDNS request
    combined_data = "${data.linode_profile.me.username}-${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip}"
    hashed_data   = sha256("${local.combined_data}-${var.linode_config.secret_key}")
}

# Update DDNS
data "http" "ddns" {
  depends_on = [ data.kubernetes_service.nginx ]
  
  url    = "http${var.dns.ddns_secure ? "s" : ""}://${var.dns.ddns}/create"
  method = "POST"

  request_headers = {
    "Content-Type" = "application/json"
  } 

  # Encode the request body as JSON
  request_body = jsonencode({
    "username" = data.linode_profile.me.username  
    "ip" = data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
    "hash" = local.hashed_data # Hashed data to sign the request
  })
  
}