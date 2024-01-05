# helm-certmanager.tf

# Create the cert-manager namespace
resource "kubernetes_namespace" "cert_manager" {
  depends_on = [ data.linode_lke_cluster.lke_cluster ]

  metadata {
    name = "cert-manager"
  }
}

# Deploy cert-manager via Helm
resource "helm_release" "cert_manager" {
  depends_on = [ kubernetes_namespace.cert_manager ]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata.0.name

  values = ["${file("${path.module}/values/cert-manager.yaml")}"] # Use the values file in the module directory

  # Create the CustomResourceDefinitions and wait for them to be ready before deploying the cert-manager Helm chart
  set {
    name  = "installCRDs"
    value = "true"
  }

}

# Create a secret containing the Linode API token
resource "kubernetes_secret" "letsencrypt_linode_api_token_secret" {
    depends_on = [ kubernetes_namespace.cert_manager ]
  metadata {
    name      = "letsencrypt-linode-api-token-secret"
    namespace = kubernetes_namespace.cert_manager.metadata.0.name
  }

  data = {
    "api-token" = var.linode_config.api_token
  }
}

# Create the _STAGING_ ClusterIssuer for Let's Encrypt
resource "kubectl_manifest" "cluster_issuer_staging" {
  depends_on = [ helm_release.cert_manager ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: "${var.linode_config.email}"
    server: "https://acme-staging-v02.api.letsencrypt.org/directory"
    privateKeySecretRef:
      name: issuer-letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
YAML
}
  
# Create the _PRODUCTION_ ClusterIssuer for Let's Encrypt
resource "kubectl_manifest" "cluster_issuer_production" {
  depends_on = [ helm_release.cert_manager ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    email: "${var.linode_config.email}"
    server: "https://acme-v02.api.letsencrypt.org/directory"
    privateKeySecretRef:
      name: issuer-letsencrypt-production
    solvers:
    - http01:
        ingress:
          class: nginx
YAML
}