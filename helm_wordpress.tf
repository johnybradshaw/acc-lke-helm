# helm_wordpress.tf
# Get the current user's profile
data "linode_profile" "me" {}

# Create a namespace for wordpress
resource "kubernetes_namespace" "wordpress" {
    depends_on = [ data.linode_lke_cluster.lke_cluster ]
    
    metadata {
        name = "wordpress"
    }
}

# Create a random user for Wordpress
resource "random_string" "wordpressUsername" {
  length            = 8
  special           = false
  upper             = false
  numeric           = false
}

# Create a random password for Wordpress
resource "random_password" "wordpressPassword" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a Wordpress Helm release
resource "helm_release" "wordpress" {
    depends_on = [ helm_release.ingress-nginx, 
        helm_release.metrics-server,
        helm_release.cert_manager,
        kubernetes_namespace.wordpress ] # Deploy Metrics-Server & Cert-Manager first

    name = "wordpress"
    repository = "https://charts.bitnami.com/bitnami"
    chart = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name

    values = ["${file("${path.module}/values/wordpress.yaml")}"] # Use the values file in the module directory

    # Set the storage class to the default
    set {
        name  = "global.storageClass"
        value = "linode-block-storage-retain"
    }
    # Use a ClusterIP
    set {
        name = "service.type"
        value = "ClusterIP"
    }
    # Use an IngressClass
    set {
        name  = "ingress.ingressClassName"
        value = "nginx"
    }
    # Use an Ingress
    set {
        name  = "ingress.enabled"
        value = "true"
    }
    # Set the hostname for the ingress (Previously ${data.linode_profile.me.username})
    set {
        name  = "ingress.hostname"
        value = "${local.subdomain}.${var.dns.ddns}"
    }
    # Enable TLS on the ingress
    set {
        name  = "ingress.tls"
        value = "true"
    }
    # Use Letsencrypt
    set {
      name = "ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "${var.production ? "letsencrypt-production" : "letsencrypt-staging"}"
    }
    # Create a MariaDB database
    set {
        name = "mariadb.enabled"
        value = "true" # Enable MariaDB
    }
    # Enable replication on the MariaDB database
    set {
        name = "mariadb.architecture"
        value = "replication" # Use replication
    }
    set {
        name = "wordpressEmail"
        value = data.linode_profile.me.email # Use the current user's email address
    }
    set {
        name = "wordpressUsername"
        value = random_string.wordpressUsername.result # Generate a random username
    }
    set {
        name = "wordpressPassword"
        value = random_password.wordpressPassword.result # Use the random password generated above
    }
    set {
        name = "wordpressBlogName"
        value = "${local.blogname}'s Really Cool Blog"
    }
}
