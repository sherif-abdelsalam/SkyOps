
variable "env" {
    description = "The environment for which to create the VPC (e.g., dev, staging, prod)"
    type        = string
}

variable "eks_name" {
    description = "The name of the EKS cluster to associate with the subnets"
    type        = string
}


variable "eks_version" {
    description = "The version of EKS to use for the cluster"
    type        = string
    default     = "1.36"
}

variable "private_subnet_ids" {
    description = "List of subnet IDs to use for the EKS cluster"
    type        = list(string)
}