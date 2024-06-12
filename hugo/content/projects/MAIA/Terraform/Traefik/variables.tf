variable "acme_email" {
  type        = string
  description = "Email Address to use for ACME Registration"
}
variable "load_balancer_ip" {
  type        = string
  description = "Load Balancer IP Address"
}

variable "traefik_resolver" {
  type        = string
  description = "Traefik Certificate Resolver"
}