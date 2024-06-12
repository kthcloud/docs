resource "kubernetes_namespace" "traefik_namespace" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_cluster_role" "traefik_role" {
  metadata {
    name = "traefik-role"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["networking.k8s.io", "extensions"]
    resources  = ["ingresses", "ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io", "extensions"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["traefik.containo.us"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik_role_binding" {
  metadata {
    name = "traefik-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "traefik-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "traefik-account"
    namespace = "traefik"
  }
}

resource "kubernetes_service_account" "traefik_account" {
  metadata {
    name      = "traefik-account"
    namespace = "traefik"
  }
}

resource "kubernetes_deployment" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
    labels    = {
      app = "traefik"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik"
        }
      }

      spec {
        service_account_name = "traefik-account"
        container {
          image = "traefik:v2.9.6"
          name  = "traefik"
          env {
            name  = "ACME_EMAIL"
            value = var.acme_email
          }
          env {
            name  = "RESOLVER"
            value = var.traefik_resolver
          }
          args = [
            '--entrypoints.web.http.redirections.entrypoint.to=websecure',
            '--entrypoints.web.http.redirections.entrypoint.scheme=https',
            "--global.checknewversion",
            "--global.sendanonymoususage",
            "--entrypoints.metrics.address=:9100/tcp",
            "--entrypoints.traefik.address=:9000/tcp",
            "--api.dashboard=true",
            "--ping=true",
            "--metrics.prometheus=true",
            "--metrics.prometheus.entrypoint=metrics",
            "--providers.kubernetescrd",
            "--providers.kubernetesingress",
            "--entrypoints.websecure.http.tls=true",
            "--api.insecure",
            "--accesslog",
            "--entrypoints.web.Address=:80",
            "--entryPoints.websecure.forwardedHeaders.insecure",
            "--entryPoints.web.forwardedHeaders.insecure",
            "--entrypoints.websecure.Address=:443",
            "--certificatesresolvers.$(RESOLVER).acme.httpchallenge=true",
            "--certificatesresolvers.$(RESOLVER).acme.httpchallenge.entrypoint=web",
            "--certificatesresolvers.$(RESOLVER).acme.email=$(ACME_EMAIL)",
            "--certificatesresolvers.$(RESOLVER).acme.storage=acme.json",
            "--certificatesresolvers.$(RESOLVER).acme.caserver=https://acme-v02.api.letsencrypt.org/directory"
          ]
          port {
            container_port = 9100
            name           = "metrics"
            protocol       = "TCP"
          }

          port {
            container_port = 9000
            name           = "traefik"
          }

          port {
            container_port = 8080
            name           = "admin"
          }

          port {
            container_port = 443
            name           = "websecure"
          }

          port {
            container_port = 80
            name           = "web"
          }


        }
      }
    }
  }
}

resource "kubernetes_service" "traefik_service" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_deployment.traefik.metadata.0.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.traefik.metadata.0.name
    }
    external_ips = [
      var.load_balancer_ip
    ]
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
      name        = "web"
    }
    port {
      port        = 8080
      target_port = 8080
      name        = "admin"
    }
    port {
      port        = 443
      target_port = 443
      name        = "websecure"
    }
  }
}