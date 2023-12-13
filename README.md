# acc-lke-helm
Deploy Helm charts to LKE

<!-- BEGIN_TF_DOCS -->
<!-- The module-name will be auto generated by the script -->
# acc-lke-helm *module*

This module deploys NGINX-Ingress, Metrics Server, Cert-Manager, and Wordpress on a [Linode Kubernetes (LKE) Cluster](https://www.linode.com/docs/products/compute/kubernetes/) on the [Akamai Connected Cloud](https://www.akamai.com/solutions/cloud-computing) using [Terraform](https://terraform.io) and Helm Charts.

## Important

The readme.md has the following sections:

- Requirements - Min requirements for the module to run
- Providers - Providers required by the module
- Inputs- Inputs to the module
- Outputs - Outputs from the module
- Usage - How to use the module

#### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.5.7)

- <a name="requirement_helm"></a> [helm](#requirement_helm) (>= 2.11.0)

- <a name="requirement_kubectl"></a> [kubectl](#requirement_kubectl) (>= 1.14.0)

- <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) (>= 2.23.0)

- <a name="requirement_linode"></a> [linode](#requirement_linode) (>= 2.9.3)

- <a name="requirement_random"></a> [random](#requirement_random) (>= 2.3.0)

#### Providers

The following providers are used by this module:

- <a name="provider_helm"></a> [helm](#provider_helm) (2.12.1)

- <a name="provider_http"></a> [http](#provider_http) (3.4.0)

- <a name="provider_kubectl"></a> [kubectl](#provider_kubectl) (1.14.0)

- <a name="provider_kubernetes"></a> [kubernetes](#provider_kubernetes) (2.24.0)

- <a name="provider_linode"></a> [linode](#provider_linode) (2.10.1)

- <a name="provider_random"></a> [random](#provider_random) (3.6.0)

#### Required Inputs

The following input variables are required:

##### <a name="input_dns"></a> [dns](#input_dns)

Description: DNS variables

Type:

```hcl
object({
      ddns = string # Domain name to update
      ddns_secure = bool # Whether to use HTTPS for the DDNS update
    })
```

##### <a name="input_linode_config"></a> [linode_config](#input_linode_config)

Description: n/a

Type:

```hcl
object({
    email     = string
    api_token = string
    secret_key = string # Used to sign the DDNS request
  })
```

##### <a name="input_lke_cluster_id"></a> [lke_cluster_id](#input_lke_cluster_id)

Description: LKE Cluster ID

Type: `string`

#### Optional Inputs

The following input variables are optional (have default values):

##### <a name="input_production"></a> [production](#input_production)

Description: Use production certificates (true) or staging certificates (false)

Type: `bool`

Default: `false`

#### Outputs

The following outputs are exported:

##### <a name="output_wordpress"></a> [wordpress](#output_wordpress)

Description: Wordpress URL

##### <a name="output_wordpressAdmin"></a> [wordpressAdmin](#output_wordpressAdmin)

Description: Wordpress Admin URL

##### <a name="output_wordpressPassword"></a> [wordpressPassword](#output_wordpressPassword)

Description: Wordpress Password

##### <a name="output_wordpressUsername"></a> [wordpressUsername](#output_wordpressUsername)

Description: Wordpress Username

## Usage

Sample usage of this module is as shown below. For detailed info, look at inputs and outputs.

### Step 1

In your main.tf, add the following code:
<!-- NOTE: The package-source and version x.x.x will be auto populated by the ci job. You do not need to change anything here. -->
```hcl
module "lke-helm" {
    
    source = "./modules/lke-helm"

    linpde_config = var.linode_config # Pass the Linode configuration to the module
    lke_cluster_id = module.lke.cluster_id # Pass the LKE cluster configuration to the module
    dns = var.dns # Pass the DNS configuration to the module
    production = true # Pass the production flag to the module
}
```

#### Note

- **lke** is the name of the module. You can use any name you want.

### Step 2

In your provider.tf, add the following code, if it doesn't exist already:

```hcl
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
```

### Step 3

Verify your settings using the following command:

``` bash
terraform init
terraform plan
```

### Step 4

Apply the changes

``` bash
terraform apply
```
<!-- END_TF_DOCS -->