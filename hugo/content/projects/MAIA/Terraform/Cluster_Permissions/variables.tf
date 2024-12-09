variable "kube_context" {
  type        = string
  description = "Kubeconfig Context"
}
variable "admin_group" {
  type        = string
  description = "Admin Group"
}

variable "kubeconfig_path" {
    type        = string
    description = "Path to kubeconfig file"
}