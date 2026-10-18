# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-node-group-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["106.219.134.237/32"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_policy
  ]

  tags = {
    Name = var.cluster_name
  }
}

# OIDC Provider
resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ephemeral_ports" {
  description                  = "Allow pods to communicate with the cluster API Server"
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_all_traffic" {
  description       = "Allow cluster to communicate with any destination"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
}

# Node Security Group
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_ephemeral_ports" {
  description                  = "Allow cluster to communicate with nodes"
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_ingress_rule" "node_webhook" {
  description                  = "Allow pods to communicate with the cluster API Server"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_ingress_rule" "node_self" {
  description                  = "Allow nodes to communicate with each other"
  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "-1"
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.node.id
}

resource "aws_vpc_security_group_egress_rule" "node_all_traffic" {
  description       = "Allow nodes to communicate with any destination"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.node.id
  cidr_ipv4         = "0.0.0.0/0"
}

# Public Node Group
resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-public-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.public_node_group.subnet_ids

  scaling_config {
    min_size     = var.public_node_group.min_size
    max_size     = var.public_node_group.max_size
    desired_size = var.public_node_group.desired_size
  }

  instance_types = var.public_node_group.instance_types

  labels = {
    node_type = "public"
  }

  tags = {
    Name = "${var.cluster_name}-public-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_container_registry_policy,
  ]
}

# Private Node Group
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-private-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_node_group.subnet_ids

  scaling_config {
    min_size     = var.private_node_group.min_size
    max_size     = var.private_node_group.max_size
    desired_size = var.private_node_group.desired_size
  }

  instance_types = var.private_node_group.instance_types

  labels = {
    node_type = "private"
  }

  tags = {
    Name = "${var.cluster_name}-private-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_container_registry_policy,
  ]
}

# Cluster Autoscaler IAM Role for IRSA
data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json

  tags = {
    Name = "${var.cluster_name}-cluster-autoscaler"
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "eks:DescribeNodegroup",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

