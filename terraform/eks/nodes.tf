resource "aws_iam_role" "node_role" {
  name = "${var.project_name}-${var.environment}-eks-node-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_eks_node_group" "general" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  version = aws_eks_cluster.eks_cluster.version
  node_group_name = "general"
  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids = aws_subnet.private_subnet[*].id

  capacity_type = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size = 2
    min_size = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.node_role-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_role-AmazonEKSWorkerNodePolicy
   ]
   
   # Allow external changes on Terraform plan
   lifecycle {
     ignore_changes = [ scaling_config[0].desired_size ] # Ignore Autoscalling
   }

   tags = {
    name = "${var.project_name}-${var.environment}-node_group"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
   }
}