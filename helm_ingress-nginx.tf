# helm_ingress-nginx.tf

# Deploy ingress-nginx
resource "helm_release" "ingress-nginx" {
    depends_on = [ helm_release.cert_manager ]

    name = "ingress-nginx"
    repository = "https://kubernetes.github.io/ingress-nginx"
    chart = "ingress-nginx"

    values = ["${file("${path.module}/values/ingress-nginx.yaml")}"] # Use the values file in the module directory

    # # Use the existing LoadBalancer service
    # set {
    #   name = "annotations.service\\.beta\\.kubernetes\\.io/linode-loadbalancer-nodebalancer-id"
    #   value = var.linode_nodebalancer_id
    # }

}

# Find the Nginx service
data "kubernetes_service" "nginx" {
    depends_on = [ helm_release.ingress-nginx ]

    metadata {
        name = "${helm_release.ingress-nginx.name}-controller"
        namespace = helm_release.ingress-nginx.namespace
    }
}