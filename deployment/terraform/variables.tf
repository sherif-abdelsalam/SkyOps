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