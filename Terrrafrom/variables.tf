variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "aws-dev-cluster"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (must be a currently supported version)"
  type        = string
  default     = "1.34"
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for cost optimization (DEV environment). Set to false for production HA."
  type        = bool
  default     = true
}

variable "public_node_group_min_size" {
  description = "Minimum size of the public node group"
  type        = number
  default     = 1
}

variable "public_node_group_max_size" {
  description = "Maximum size of the public node group"
  type        = number
  default     = 3
}

variable "public_node_group_desired_size" {
  description = "Desired size of the public node group"
  type        = number
  default     = 1
}

variable "private_node_group_min_size" {
  description = "Minimum size of the private node group"
  type        = number
  default     = 1
}

variable "private_node_group_max_size" {
  description = "Maximum size of the private node group"
  type        = number
  default     = 3
}

variable "private_node_group_desired_size" {
  description = "Desired size of the private node group"
  type        = number
  default     = 1
}

variable "ecr_repository_names" {
  description = "List of ECR repository names to create. Empty list skips ECR module."
  type        = list(string)
  default     = ["aws-dev-app"]
}
