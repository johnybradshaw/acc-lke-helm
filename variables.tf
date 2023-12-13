# variables.tf

variable "linode_config" {
  type = object({
    email     = string
    api_token = string
    secret_key = string # Used to sign the DDNS request
  })
}

variable "lke_cluster_id" {
    description   = "LKE Cluster ID"
    type          = string
}

variable "dns" {
    description = "DNS variables"
    type = object({
      ddns = string # Domain name to update
      ddns_secure = bool # Whether to use HTTPS for the DDNS update
    })
}

variable "production" {
  description = "Use production certificates (true) or staging certificates (false)"
  type = bool
  default = false
}