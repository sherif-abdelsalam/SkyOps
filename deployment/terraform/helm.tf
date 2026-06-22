resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
  namespace        = "ingress-nginx"
  create_namespace = true        # ← Helm creates the namespace automatically

  wait    = true
  timeout = 300

  values = [
    file("${path.module}/values/ingress-nginx-values.yaml")
  ]
}
  


# resource "helm_release" "argocd" {
#   name             = "argocd"
#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argo-cd"
#   namespace        = "argocd"
#   create_namespace = true
#   version          = "7.3.4"

#   values = [
#     templatefile("${path.module}/values/argocd-values.yaml", {
#       ingress_host = var.argocd_ingress_host
#     })
#   ]

#   depends_on = [
#     module.eks,
#     helm_release.ingress_nginx
#   ]
# }

