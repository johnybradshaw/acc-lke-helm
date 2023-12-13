# helm_metrics-server.tf

# Create a namespace for metrics-server
resource "kubernetes_namespace" "metrics-server" {
  metadata {
    name = "metrics-server"
  }
}

# Deploy metrics-server
resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = kubernetes_namespace.metrics-server.metadata[0].name

  values = ["${file("${path.module}/values/metrics-server.yaml")}"] # Use the values file in the module directory

  set {
    name  = "apiService.create"
    value = "true"
  }

  set_list {
    name  = "args"
    value = [
      "--kubelet-insecure-tls", # This is required for the kubelet to connect to the metrics-server
      "--kubelet-preferred-address-types=InternalIP",
    ]
  }
}

