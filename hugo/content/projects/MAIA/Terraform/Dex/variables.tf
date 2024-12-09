variable "kube_context" {
  type        = string
  description = "Kubeconfig Context"
}

variable "kubeconfig_path" {
    type        = string
    description = "Path to kubeconfig file"
}

variable "dex_hostname" {
  type        = string
  description = "Dex Hostname"
}

variable "token_expiration" {
  type        = string
  description = "Dex Token Expiration Time (in h)"
}

variable "github_client_id" {
  type        = string
  description = "GitHub Connector Client ID"
}

variable "github_client_secret" {
  type        = string
  description = "GitHub Connector Client Secret"
}

variable "github_hostname" {
  type        = string
  description = "GitHub Hostname"
}

variable "github_organization" {
  type        = string
  description = "GitHub Organization Name"
}

variable "static_secret" {
  type        = string
  description = "Static Secret"
}

variable "static_id" {
  type        = string
  description = "Static ID"
}

variable "callbacks" {
  type        = list(string)
  description = "List of Callbacks to Authenticate"
}

variable "ldap_host" {
  type        = string
  description = "LDAP Hostname"
}

variable "ldap_bind_dn" {
  type        = string
  description = "LDAP Bind DN"
}

variable "ldap_bind_pw" {
  type        = string
  description = "LDAP Bind PW"
}

variable "ldap_user_base_dn" {
  type        = string
  description = "LDAP User Base DN"
}

variable "ldap_group_base_dn" {
  type        = string
  description = "LDAP Group Base DN"
}
variable "traefik_resolver" {
  type        = string
  description = "Traefik Certificate Resolver"
}

variable "keycloack_client_id" {
    type        = string
    description = "Keycloack Client ID"
}

variable "keycloack_client_secret" {
    type        = string
    description = "Keycloack Client Secret"
}

variable "keycloack_redirect_uri" {
    type        = string
    description = "Keycloack Redirect URI"
}

variable "keycloack_issuer" {
    type        = string
    description = "Keycloack Issuer URL for OIDC"
}
