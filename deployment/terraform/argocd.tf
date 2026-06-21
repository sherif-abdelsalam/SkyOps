resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.3.4"

  values = [
    templatefile("${path.module}/values/argocd-values.yaml", {
      ingress_host = var.argocd_ingress_host
    })
  ]

  depends_on = [
    module.eks,
    helm_release.ingress_nginx
  ]
}


