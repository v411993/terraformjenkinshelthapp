# AWS Dev Infrastructure

A comprehensive AWS infrastructure project built with Terraform for deploying a DEV EKS (Elastic Kubernetes Service) cluster with security, scalability, and observability considerations.

## Overview

This project provisions a complete AWS infrastructure including:
- VPC with public and private subnets across multiple availability zones
- EKS Kubernetes cluster with managed node groups
- IAM roles with least-privilege access
- OIDC provider for Kubernetes service account IAM integration
- Cluster autoscaler IAM role configuration (IRSA)

## Architecture

The infrastructure is deployed in the `us-west-2` region and follows AWS best practices for high availability and security.

### Components

- **VPC**: 10.0.0.0/16 CIDR block with DNS support enabled
- **Public Subnets**: 3 subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) across us-west-2a, us-west-2b, us-west-2c
- **Private Subnets**: 3 subnets (10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24) across us-west-2a, us-west-2b, us-west-2c
- **Internet Gateway**: Provides internet access for public subnets
- **NAT Gateway**: 1 NAT Gateway (DEV environment) for private subnet internet access. Configurable for production HA.
- **EKS Cluster**: Kubernetes 1.34 (configurable) with control plane logging enabled
- **Node Groups**:
  - Public node group: t3.medium instances (configurable 1-3 nodes)
  - Private node group: t3.medium instances (configurable 1-3 nodes)
- **IAM Roles**: Separate roles for EKS cluster, node groups, and cluster autoscaler with least-privilege policies
- **OIDC Provider**: Enables Kubernetes service accounts to assume IAM roles (IRSA)

## Prerequisites

- Terraform >= 1.9
- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create all resources
- S3 bucket for Terraform state (created manually before first apply)

## Project Structure

```
aws-dev-infrastructure/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── backend.tf                 # S3 backend configuration
├── versions.tf                # Terraform and provider versions
├── modules/
│   ├── vpc/                   # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                   # EKS module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecr/                   # ECR module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── kubernetes/
│   └── cluster-autoscaler/
│       ├── serviceaccount.yaml
│       └── values.yaml
├── docs/
│   ├── architecture.md        # Detailed architecture documentation
│   ├── security-groups.md     # Security group documentation
│   └── screenshots.md         # Screenshots guide
└── README.md                  # This file
```

## Setup Instructions

### 1. Configure the S3 Backend

This project uses an S3 bucket for remote Terraform state and S3 native locking.

The backend is configured in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "aws-dev-infrastructure-state"
    key          = "dev/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

Make sure the S3 bucket `aws-dev-infrastructure-state` exists before running `terraform init`.

**Note**: This configuration uses S3 native locking. A DynamoDB locking table is not required.

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply the Infrastructure

```bash
terraform apply
```

### 5. Configure kubectl

After the EKS cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --name aws-dev-cluster --region us-west-2
```

### 6. Verify the Cluster

```bash
kubectl get nodes
kubectl get svc
```

## Module Descriptions

### VPC Module (`modules/vpc`)

Creates a Virtual Private Cloud with:
- Public and private subnets across 3 availability zones
- Internet Gateway for public subnet internet access
- NAT Gateway (single for DEV, configurable) for private subnet internet access
- Route tables for proper traffic routing

**NAT Gateway Design Decision**:
- **DEV Environment**: Single NAT Gateway for cost optimization (~$32/month vs ~$98/month for 3)
- **Production**: Set `single_nat_gateway = false` for high availability across all AZs
- **Trade-off**: Single NAT Gateway becomes a single point of failure but significantly reduces costs

### EKS Module (`modules/eks`)

Provisions:
- EKS cluster with Kubernetes 1.34 (configurable via `cluster_version` variable)
- IAM roles for cluster and node groups with least-privilege policies
- OIDC provider for IRSA (IAM Roles for Service Accounts)
- IAM role for cluster autoscaler with tag-based least-privilege policy
- Security groups for cluster and nodes
- Public and private node groups with auto-scaling
- Cluster logging enabled for audit and troubleshooting
- Node groups tagged for cluster autoscaler discovery

### ECR Module (`modules/ecr`)

Creates ECR repositories for container images with:
- Image scanning on push
- Lifecycle policies to manage image retention

**Note**: ECR repositories are optional. Set `ecr_repository_names` variable to define which repositories to create. The current default creates the `aws-dev-app` repository.

## Security Considerations

- **Least Privilege IAM**: All IAM roles use AWS managed policies with minimal required permissions
- **Private Subnets**: EKS nodes in private subnets for enhanced security
- **Security Groups**: Restrictive security groups with only necessary ports open
- **VPC Isolation**: VPC with separate public and private subnets
- **OIDC Provider**: Enables fine-grained IAM permissions for Kubernetes workloads
- **Cluster Autoscaler IAM**: Tag-based policy restricts autoscaler to only modify tagged ASGs
- **EBS Encryption**: EBS volumes use default KMS encryption

## Cluster Autoscaler

The infrastructure includes IAM configuration for Cluster Autoscaler using IRSA (IAM Roles for Service Accounts).

### IAM Configuration

- IAM role created: `aws-dev-cluster-cluster-autoscaler`
- IAM role ARN:
  `arn:aws:iam::951897726665:role/aws-dev-cluster-cluster-autoscaler`
- IAM policy provides read access to Auto Scaling Groups and write access restricted to ASGs tagged for Cluster Autoscaler.
- EKS node groups are tagged for Cluster Autoscaler auto-discovery.

### Kubernetes Configuration

Cluster Autoscaler configuration is maintained under:

```text
kubernetes/
└── cluster-autoscaler/
    ├── serviceaccount.yaml
    └── values.yaml
```

### Helm Deployment

Cluster Autoscaler is deployed using Helm chart version `9.59.0`.

The Helm deployment is configured with the following settings:

- Cloud provider: AWS
- AWS Region: `us-west-2`
- EKS cluster: `aws-dev-cluster`
- Auto-discovery of EKS node groups
- Existing Kubernetes ServiceAccount
- IRSA IAM role for AWS permissions

The Cluster Autoscaler configuration is maintained in:

```text
kubernetes/cluster-autoscaler/values.yaml
```
### Verification

Verify the Helm release:

```bash
helm list -n kube-system
```

Verify the Cluster Autoscaler pod:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=cluster-autoscaler
```

Verify the Cluster Autoscaler deployment:

```bash
kubectl get deployment -n kube-system
```

Check Cluster Autoscaler logs:

```bash
kubectl logs -n kube-system deployment/cluster-autoscaler-aws-cluster-autoscaler
```

The Cluster Autoscaler should successfully discover the public and private EKS node groups through AWS Auto Scaling Group tags.

## Configuration Variables

Key configurable variables in `variables.tf`:

- `cluster_name`: EKS cluster name (default: "aws-dev-cluster")
- `cluster_version`: Kubernetes version (default: "1.34")
- `single_nat_gateway`: Use single NAT Gateway for cost savings (default: true)
- `public_node_group_min_size/max_size/desired_size`: Public node group scaling
- `private_node_group_min_size/max_size/desired_size`: Private node group scaling
- `ecr_repository_names`: List of ECR repository names to create (default: ["aws-dev-app"])

## Outputs

After applying the infrastructure, Terraform outputs:
- VPC ID and subnet IDs
- EKS cluster endpoint and ID
- Security group IDs
- IAM role ARNs (cluster, node groups, cluster autoscaler)
- ECR repository URLs (if created)
- kubectl configuration command

## Cost Considerations

This infrastructure will incur the following costs (estimated with default configuration):
- EKS Cluster: ~$0.10/hour (~$73/month)
- NAT Gateway: ~$0.045/hour (~$32/month for 1 gateway with single_nat_gateway=true)
- EBS Volumes: ~$0.08/GB/month
- EC2 Instances: ~$0.0416/hour per t3.medium (~$30/month per instance, 2 instances = ~$60/month)
- Data Transfer: Varies based on usage

**Total estimated minimum cost: ~$165-200/month** (with single NAT Gateway and 2 nodes)

**Cost Optimization Notes**:
- Single NAT Gateway saves ~$66/month compared to 3 NAT Gateways
- Trade-off: Single NAT Gateway is a single point of failure
- For production HA, set `single_nat_gateway = false` (adds ~$66/month)

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy
```

Note: The S3 bucket for Terraform state must be deleted manually after destroying the infrastructure.

## Documentation

- [Architecture Documentation](docs/architecture.md) - Detailed architecture explanation
- [Security Groups Documentation](docs/security-groups.md) - Security group rules and purposes
- [Screenshots](docs/screenshots.md) - Visual documentation of the infrastructure

## Troubleshooting

### Terraform State Lock Issues

If you encounter state lock issues with S3 native locking, you can manually remove the lock file:
```bash
aws s3api delete-object \
    --bucket aws-dev-infrastructure-state \
    --key dev/terraform.tfstate.tflock
```

### EKS Cluster Access Issues

If you cannot access the cluster, ensure:
- Your AWS credentials are valid
- Your IAM user has the necessary EKS permissions
- The cluster endpoint is accessible from your network

## License

This project is provided as-is for educational and development purposes.

## Support

For issues or questions, please refer to the AWS documentation:
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
