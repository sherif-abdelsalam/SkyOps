variable "env" {
  description = "The environment for which to create the VPC (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  type = string
}

variable "zone1" {
  type = string
}
variable "zone2" {
  type = string
}
variable "zone3" {
  type = string
}

variable "eks_name" {
  description = "The name of the EKS cluster to associate with the subnets"
  type        = string
}


variable "eks_version" {
  description = "The version of EKS to use for the cluster"
  type        = string
}

variable "ingress_nginx_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.10.1"
}


variable "argocd_ingress_host" {
  description = "The hostname for ArgoCD ingress (e.g., argocd.example.com)"
  type        = string
}


variable "eso_namespace" {
  description = "The Kubernetes namespace for ESO components"
  type        = string
}

variable "app_namespace" {
  description = "The Kubernetes namespace for application deployments"
  type        = string
}

variable "eso_service_account" {
  description = "The name of the Kubernetes Service Account for ESO"
  type        = string
}


variable "secret_arns" {
  type        = list(string)
  description = "List of Secrets Manager ARNs ESO is allowed to read"
}

variable "enable_external_secrets_crds" {
  type = bool
  default = true
}


variable "aws_account_id" {
  type = string
}