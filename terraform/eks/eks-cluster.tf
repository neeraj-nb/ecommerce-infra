resource "aws_iam_role" "cluster_role" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name = "${var.cluster_name}-${var.environment}"
  role_arn = aws_iam_role.cluster_role.arn
  version = var.kubernetes_version

  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access = true

    subnet_ids = aws_subnet.private_subnet[*].id
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
   ]

   tags = {
    name = "${var.project_name}-${var.environment}-cluster}"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
   }
}