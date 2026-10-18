output "repository_urls" {
  description = "URLs of the ECR repositories"
  value       = aws_ecr_repository.this[*].repository_url
}
