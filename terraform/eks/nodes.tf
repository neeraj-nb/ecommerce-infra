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

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks_cluster.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
}

resource "aws_eks_node_group" "general" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  version = aws_eks_cluster.eks_cluster.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_group_name = "general"
  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids = aws_subnet.private_subnet[*].id

  capacity_type = "ON_DEMAND"
  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = "lab"
    source_security_group_ids = [aws_security_group.eks_woker_sg.id]
  }

  scaling_config {
    desired_size = 2
    max_size = 3
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
    Name = "${var.project_name}-${var.environment}-node_group"
    project = var.project_name
    environment = var.environment
    managed = "terraform"
   }
}