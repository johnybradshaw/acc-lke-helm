locals {
    #depends_on = [ data.kubernetes_service.wordpress ]
    # Set the subdomain
    subdomain = lower(var.subdomain) #Previously ${data.linode_profile.me.username}
    # Uppercase the first letter for the blog name
    blogname = "${upper(substr(var.subdomain, 0, 1))}${lower(substr(var.subdomain, 1, length(var.subdomain)))}"
    # Hashed data to sign the DDNS request
    combined_data = "${var.subdomain}-${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip}"
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
    "username" = local.subdomain
    "ip" = data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
    "hash" = local.hashed_data # Hashed data to sign the request
  })
  
}