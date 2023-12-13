# helm_wordpress.tf
# Get the current user's profile
data "linode_profile" "me" {}

# Create a namespace for wordpress
resource "kubernetes_namespace" "wordpress" {
    metadata {
        name = "wordpress"
    }
}

# Create a random password for Wordpress
resource "random_password" "wordpressPassword" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a Wordpress Helm release
resource "helm_release" "wordpress" {
    depends_on = [ helm_release.ingress-nginx, kubernetes_namespace.wordpress ]

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
    # Set the hostname for the ingress
    set {
        name  = "ingress.hostname"
        value = "${data.linode_profile.me.username}.${var.dns.ddns}"
    }
    # Enable TLS on the ingress
    set {
        name  = "ingress.tls"
        value = "true"
    }
    # Use Letsencrypt
    set {
      name = "ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt-staging"
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
        value = data.linode_profile.me.username # Use the current user's username
    }
    set {
        name = "wordpressPassword"
        value = random_password.wordpressPassword.result # Use the random password generated above
    }
    set {
        name = "wordpressBlogName"
        value = "${data.linode_profile.me.username}'s Really Cool Blog"
    }
}