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



# resource "kubernetes_namespace" "external_secrets" {
#   metadata {
#     name = var.eso_namespace 
#   }
# }

# resource "kubernetes_namespace" "app" {
#   metadata {
#     name = var.app_namespace   
#   }
# }# اسمه "app-gamma" — namespace التطبيق


# resource "helm_release" "external_secrets" {
#   name       = "external-secrets"
#   namespace  = kubernetes_namespace.external_secrets.metadata[0].name
#   repository = "https://charts.external-secrets.io"
#   chart      = "external-secrets"
#   version    = "0.10.5"           # ← pin the version دايماً

#   wait    = true
#   timeout = 600

#   values = [yamlencode({
#     installCRDs = true         
#     serviceAccount = {
#       create = true
#       name   = var.eso_service_account
#       annotations = {
#         "eks.amazonaws.com/role-arn" = var.eso_irsa_role_arn  # ← IRSA هنا
#       }
#     }
#   })]
# }