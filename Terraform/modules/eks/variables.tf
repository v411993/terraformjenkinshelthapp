variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "public_node_group" {
  description = "Configuration for the public node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    subnet_ids     = list(string)
  })
}

variable "private_node_group" {
  description = "Configuration for the private node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    subnet_ids     = list(string)
  })
}
