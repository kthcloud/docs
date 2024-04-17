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
  name             = "loginapp"
  repository       = "https://storage.googleapis.com/loginapp-releases/charts/"
  chart            = "loginapp"
  version          = "1.3.0"
  namespace        = "authentication"
  create_namespace = true

  values = [
    file("./values.yaml")
  ]

  set {
    name  = "ingress.hosts[0].host"
    value = var.loginapp_hostname
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
    value = var.loginapp_hostname
  }


  set {
    name  = "config.clientRedirectURL"
    value = format("%s%s%s", "https://", var.loginapp_hostname, "/callback")
  }


  set {
    name  = "config.secret"
    value = var.secret
  }
  set {
    name  = "config.clientID"
    value = var.client_id
  }
  set {
    name  = "config.clientSecret"
    value = var.client_secret
  }

  set {
    name  = "config.issuerURL"
    value = var.issuer_url
  }

  set {
    name  = "config.clusters[0].server"
    value = var.cluster_server_address
  }

  set {
    name  = "config.clusters[0].name"
    value = var.cluster_server_name
  }

  set {
    name  = "config.clusters[0].insecure-skip-tls-verify"
    value = "\"false\""
  }

  set {
    name  = "config.clusters[0].certificate-authority"
    value = file(var.ca_file)
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