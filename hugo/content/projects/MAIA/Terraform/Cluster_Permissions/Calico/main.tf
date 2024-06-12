resource "kubernetes_cluster_role" "cluster_role_admin" {
  metadata {
    name = "cluster-role-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }

}

resource "kubernetes_cluster_role_binding" "cluster_role_binding_admin" {
  metadata {
    name = "cluster-role-binding-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-role-admin"
  }
  subject {
    kind      = "Group"
    name      = var.admin_group
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "cluster_role_read" {
  metadata {
    name = "cluster-role-read"
  }

  rule {
    api_groups = ["*"]
    resources  = ["namespaces", "nodes", "pods"]
    verbs      = ["get", "list"]
  }

  #rule {
  #  non_resource_urls = ["*"]
  #  verbs             = ["get", "watch", "list"]
  #}

  #rule {
  #  api_groups = [""]
  #  resources  = ["pods/exec"]
  #  verbs      = ["create"]
  #}

}
resource "kubernetes_cluster_role_binding" "cluster_role_authenticated_read" {
  metadata {
    name = "cluster-role-authenticated-read"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-role-read"
  }
  subject {
    kind      = "Group"
    name      = "system:authenticated"
    api_group = "rbac.authorization.k8s.io"
  }
}
