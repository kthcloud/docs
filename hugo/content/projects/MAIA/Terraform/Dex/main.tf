terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
  }
}



provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

resource "helm_release" "dex" {
  name             = "dex"
  repository       = "https://charts.dexidp.io"
  chart            = "dex"
  version          = "0.12.1"
  namespace        = "authentication"
  create_namespace = true

  values = [
    file("values.yaml")
  ]

  set {
    name  = "ingress.hosts[0].host"
    value = var.dex_hostname
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.dex_hostname
  }

  set {
    name  = "config.issuer"
    value = format("%s%s", "https://", var.dex_hostname)
  }

  set {
    name  = "config.expiry.idTokens"
    value = var.token_expiration
  }

  #set {
  #  name  = "config.connectors[0].type"
  #  value = "github"
  #}

  #set {
  #  name  = "config.connectors[0].id"
  #  value = "github"
  #}

  #set {
  #  name  = "config.connectors[0].name"
  #  value = "GitHub"
  #}

  #set {
  #  name  = "config.connectors[0].config.clientID"
  #  value = var.github_client_id
  #}

  #set {
  #  name  = "config.connectors[0].config.clientSecret"
  #  value = var.github_client_secret
  #}

  #set {
  #  name  = "config.connectors[0].config.redirectURI"
  #  value = format("%s%s%s", "https://", var.dex_hostname, "/callback")
  #}

  #set {
  #  name  = "config.connectors[0].config.hostName"
  #  value = var.github_hostname
  #}

  #set {
  #  name  = "config.connectors[0].config.orgs[0].name"
  #  value = var.github_organization
  #}

  set {
    name  = "config.connectors[0].type"
    value = "ldap"
  }

  set {
    name  = "config.connectors[0].id"
    value = "ldap"
  }

  set {
    name  = "config.connectors[0].name"
    value = "LDAP"
  }
  set {
    name  = "config.connectors[0].config.host"
    value = var.ldap_host
  }

  set {
    name  = "config.connectors[0].config.insecureNoSSL"
    value = true
  }

  set {
    name  = "config.connectors[0].config.bindDN"
    value = replace(var.ldap_bind_dn, ",", "\\,")
  }

  set {
    name  = "config.connectors[0].config.bindPW"
    value = var.ldap_bind_pw
  }

  set {
    name  = "config.connectors[0].config.usernamePrompt"
    value = "SSO Username"
  }

  set {
    name  = "config.connectors[0].config.userSearch.baseDN"
    value = replace(var.ldap_user_base_dn, ",", "\\,")

  }

  set {
    name  = "config.connectors[0].config.userSearch.filter"
    value = "(objectClass=person)"
  }

  set {
    name  = "config.connectors[0].config.userSearch.username"
    value = "uid"
  }

  set {
    name  = "config.connectors[0].config.userSearch.idAttr"
    value = "uid"
  }

  set {
    name  = "config.connectors[0].config.userSearch.emailAttr"
    value = "mail"
  }

  set {
    name  = "config.connectors[0].config.userSearch.nameAttr"
    value = "cn"
  }

  set {
    name  = "config.connectors[0].config.groupSearch.baseDN"
    value = replace(var.ldap_group_base_dn, ",", "\\,")
  }

  set {
    name  = "config.connectors[0].config.groupSearch.filter"
    value = "(objectClass=posixGroup)"
  }

  set {
    name  = "config.connectors[0].config.groupSearch.userMatchers[0].userAttr"
    value = "uid"
  }

  set {
    name  = "config.connectors[0].config.groupSearch.userMatchers[0].groupAttr"
    value = "memberUid"
  }

  set {
    name  = "config.connectors[0].config.groupSearch.nameAttr"
    value = "cn"
  }


  set {
    name  = "config.connectors[1].id"
    value = "keycloack"
  }

  set {
    name  = "config.connectors[1].name"
    value = "keycloack"
  }

  set {
    name  = "config.connectors[1].type"
    value = "oidc"
  }

  set {
    name  = "config.connectors[1].config.clientID"
    value = var.keycloack_client_id
  }

  set {
    name  = "config.connectors[1].config.clientSecret"
    value = var.keycloack_client_secret
  }

  set {
    name  = "config.connectors[1].config.redirectURI"
    value = var.keycloack_redirect_uri
  }

  set {
    name  = "config.connectors[1].config.issuer"
    value = var.keycloack_issuer
  }

  set {
    name  = "config.connectors[1].userNameKey"
    value = "preferred_username"
  }

set_list {
    name  = "config.connectors[1].scopes"
    value = ["openid","email","profile"]
  }



  set {
    name  = "config.staticClients[0].secret"
    value = var.static_secret
  }

  set {
    name  = "config.staticClients[0].id"
    value = var.static_id
  }

    set_list {
    name  = "config.staticClients[0].redirectURIs"
    value = var.callbacks
  }

  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io\\/router\\.entrypoints"
    value = "websecure"
  }
  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io\\/router\\.tls"
    value = "\"true\""
  }
  set {
    name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io\\/router\\.tls\\.certresolver"
    value = var.traefik_resolver
  }


}