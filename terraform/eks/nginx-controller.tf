resource "helm_release" "nginx_external" {
  name = "external"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "ingress"
  create_namespace = true
  version = "4.12.3"

  values = [file("./values/nginx-ingress-external.yaml")]

  depends_on = [ helm_release.aws_lbc ]
}

resource "helm_release" "nginx_internal" {
  name = "external"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "ingress"
  create_namespace = true
  version = "4.12.3"

  values = [file("./values/nginx-ingress-internal.yaml")]

  depends_on = [ helm_release.nginx_external ]
}