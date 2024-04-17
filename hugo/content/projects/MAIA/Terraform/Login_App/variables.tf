variable "loginapp_hostname" {
  type        = string
  description = "Login App Hostname"
}
variable "secret" {
  type        = string
  description = "App Secret"
}
variable "client_secret" {
  type        = string
  description = "Client Secret"
}

variable "client_id" {
  type        = string
  description = "Client ID"
}

variable "issuer_url" {
  type        = string
  description = "Issuer URL"
}

variable "cluster_server_address" {
  type        = string
  description = "Cluster Server Address"
}

variable "cluster_server_name" {
  type        = string
  description = "Cluster Server Name"
}
variable "traefik_resolver" {
  type        = string
  description = "Traefik Certificate Resolver"
}

variable "ca_file" {
  type        = string
  description = "CA File Path"
}

variable "kube_context" {
  type        = string
  description = "Kubeconfig Context"
}

variable "kubeconfig_path" {
    type        = string
    description = "Path to kubeconfig file"
}