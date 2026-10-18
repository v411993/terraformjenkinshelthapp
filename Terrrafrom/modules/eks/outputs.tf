output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "public_node_group_id" {
  description = "ID of the public node group"
  value       = aws_eks_node_group.public.id
}

output "private_node_group_id" {
  description = "ID of the private node group"
  value       = aws_eks_node_group.private.id
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the node groups"
  value       = aws_iam_role.node_group.arn
}

output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN for cluster autoscaler (IRSA)"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "cluster_autoscaler_iam_role_name" {
  description = "IAM role name for cluster autoscaler (IRSA)"
  value       = aws_iam_role.cluster_autoscaler.name
}
