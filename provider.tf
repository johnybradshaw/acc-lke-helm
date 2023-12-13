# terraform.tf

terraform {
    required_version = ">= 1.5.7"

    required_providers {
        linode = {
            source = "linode/linode"
            version = ">= 2.9.3"
            configuration_aliases = [ linode.default ]
        }
        helm = {
            source = "hashicorp/helm"
            version = ">= 2.11.0"
            configuration_aliases = [ helm.default ]
        }
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = ">= 2.23.0"
            configuration_aliases = [ kubernetes.default ]
        }
        kubectl = {
          source = "gavinbunney/kubectl"
          version = ">= 1.14.0"
          configuration_aliases = [ kubectl.default ]
        }
        random = {
            source = "hashicorp/random"
            version = ">= 2.3.0"
            configuration_aliases = [ random.default ]
        }
    }
}


# Initialise the Linode provider
provider "linode" {
    token = var.linode_config.api_token
}

# Get the LKE cluster object
data "linode_lke_cluster" "lke_cluster" {
    id = var.lke_cluster_id
}

# Decode the kubeconfig
locals {
    depends_on = [ data.linode_lke_cluster.lke_cluster ]

    kube_config_decoded = base64decode(data.linode_lke_cluster.lke_cluster.kubeconfig)
    kube_config_map     = yamldecode(local.kube_config_decoded)
    user_name           = local.kube_config_map.users[0].name
    user_token          = local.kube_config_map.users[0].user.token
}

# Initialise the Kubernetes provider
provider "kubernetes" {

    host  = local.kube_config_map.clusters[0].cluster.server
    token = local.user_token

    cluster_ca_certificate = base64decode(
        local.kube_config_map.clusters[0].cluster["certificate-authority-data"]
    )
}

# Initialise the Helm provider
provider "helm" {
    
    kubernetes {
        host  = local.kube_config_map.clusters[0].cluster.server
        token = local.user_token

        cluster_ca_certificate = base64decode(
            local.kube_config_map.clusters[0].cluster["certificate-authority-data"]
        )
    }
}

provider "random" {
  
}