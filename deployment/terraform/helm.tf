resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
  namespace        = "ingress-nginx"
  create_namespace = true 

  wait    = true
  timeout = 300

  values = [
    file("${path.module}/values/ingress-nginx-values.yaml")
  ]
}
  


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




resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "oci://quay.io/jetstack/charts"
  chart            = "cert-manager"
  version          = "v1.20.2"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
  ]
    
}


# modules/argocd-image-updater/main.tf

# resource "helm_release" "argocd_image_updater" {
#   name             = "argocd-image-updater"
#   repository       = "https://argoproj.github.io/argo-helm"
#   chart            = "argocd-image-updater"
#   version          = "0.11.0"
#   namespace        = "argocd"
#   create_namespace = false  # argocd namespace already exists

#   values = [
#     templatefile("${path.module}/values/argocd-image-updater.yaml", {
#       aws_region     = var.region
#       aws_account_id = var.aws_account_id
#     })
#   ]
# }



# data "aws_iam_policy_document" "image_updater_assume" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     principals {
#       type        = "Federated"
#       identifiers = [module.eks.oidc_provider_arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${module.eks.oidc_provider}:sub"
#       values   = ["system:serviceaccount:argocd:argocd-image-updater"]
#     }
#   }
# } 

# resource "aws_iam_role" "image_updater" {
#   name               = "argocd-image-updater"
#   assume_role_policy = data.aws_iam_policy_document.image_updater_assume.json
# }

# resource "aws_iam_role_policy" "image_updater_ecr" {
#   name = "ecr-read"
#   role = aws_iam_role.image_updater.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:DescribeImages",
#           "ecr:DescribeRepositories",
#           "ecr:ListImages"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }
