data "aws_iam_policy_document" "external_dns" {
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

resource "aws_iam_policy" "external_dns" {
  policy = file("./iam/ExternalDNSPolicy.json")
  name = "ExternalDNSPolicy"
}

resource "aws_iam_role" "external_dns" {
  name = "${var.cluster_name}-${var.environment}-external_dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  namespace = "kube-system"
  service_account = "external-dns"
  role_arn = aws_iam_role.external_dns.arn
}

resource "helm_release" "external_dns" {
  description = "External DNS"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  name = "external-dns"
  chart = "external-dns"
  namespace = "kube-system"

  set = [ 
    {
        name = "provider"
        value = "aws"
    },
    {
        name = "region"
        value = var.aws_region
    },
    {
        name = "serviceAccount.name"
        value = "external-dns"
    },
    {
        name = "txtOwnerId"
        value = "external-dns"
    },
    {
        name = "policy"
        value = "sync"
    },
    {
        name = "domainFilters"
        value = "{neerajbabu.tech}"
    },
    {
        name = "registry"
        value = "txt"
    }
  ]

  depends_on = [ 
    helm_release.aws_lbc
   ]
}