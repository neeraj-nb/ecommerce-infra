resource "aws_security_group" "eks_woker_sg" {
  name = "eks-woker-node-sg"
  description = "Security group for EKS worker node"
  vpc_id = aws_vpc.k8s-vpc.id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    description = "Allow incoming from control plane (API server)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_worker_sg"
  }
}

# resource "aws_security_group" "alb" {
#   name        = "alb-sg"
#   description = "Allow inbound traffic to ALB"
#   vpc_id      = aws_vpc.k8s-vpc.id

#   ingress {
#     description = "Allow HTTP from VPC"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }

#   ingress {
#     description = "Allow HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "alb-sg"
#   }
# }


# resource "aws_security_group_rule" "allow_alb_to_nodes_1" {
#   type                     = "ingress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.eks_woker_sg.id
#   source_security_group_id = aws_security_group.alb.id
#   description              = "Allow ALB to reach pods"

#   depends_on = [ aws_security_group.eks_woker_sg ]
# }

# resource "aws_security_group_rule" "allow_alb_to_nodes_2" {
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.eks_woker_sg.id
#   source_security_group_id = aws_security_group.alb.id
#   description              = "Allow ALB to reach pods"

#   depends_on = [ aws_security_group.eks_woker_sg ]
# }