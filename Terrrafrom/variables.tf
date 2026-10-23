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

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public Amazon EKS API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecr_repository_names" {
  description = "List of ECR repository names to create. Empty list skips ECR module."
  type        = list(string)
  default     = ["aws-dev-app"]
}
