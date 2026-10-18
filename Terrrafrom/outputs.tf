# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# EKS Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "public_node_group_id" {
  description = "ID of the public node group"
  value       = module.eks.public_node_group_id
}

output "private_node_group_id" {
  description = "ID of the private node group"
  value       = module.eks.private_node_group_id
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the node groups"
  value       = module.eks.node_group_iam_role_arn
}

output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for cluster autoscaler (IRSA)"
  value       = module.eks.cluster_autoscaler_iam_role_arn
}

output "cluster_autoscaler_iam_role_name" {
  description = "IAM role name for cluster autoscaler (IRSA)"
  value       = module.eks.cluster_autoscaler_iam_role_name
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = length(var.ecr_repository_names) > 0 ? module.ecr[0].repository_urls : []
}

# Additional Outputs
output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
}
