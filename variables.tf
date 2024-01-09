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
    description = "DDNS variables"
    type = object({
      ddns = string # DDNS to update
      ddns_secure = bool # Whether to use HTTPS for the DDNS update
    })
}

variable "production" {
  description = "Use production certificates (true) or staging certificates (false)"
  type = bool
  default = false
}

variable "subdomain" {
  description = "Subdomain for the Wordpress site"
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z]+$", var.subdomain))
    error_message = "The subdomain must only contain letters."
  }
}