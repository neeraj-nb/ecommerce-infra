data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
        "sts:AssumeRole",
        "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  name = "${var.cluster_name}-${var.environment}-aws_lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("./iam/AWSLoadBalancerController.json")
  name = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn = aws_iam_role.aws_lbc.arn
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balacer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.13.3"
  recreate_pods = true

  set = [
    {
        name = "clusterName"
        value = aws_eks_cluster.eks_cluster.name
    },
    {
        name = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    },
    {
      name = "vpcId"
      value = aws_vpc.k8s-vpc.id
    },
    # {
    #   name = "securityGroup.id"
    #   value = aws_security_group.alb.id
    # },
    #     {
    #     name = "serviceAccount.create"
    #     value = "false"
    # },
  ]

  depends_on = [ 
    aws_eks_node_group.general
   ]
}