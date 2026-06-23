############################################
# Namespaces
############################################
resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = var.eso_namespace 
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace 
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}


############################################
# ESO via Helm (CRDs included)
############################################
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace_v1.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.5"

  wait             = true
  timeout          = 600
  create_namespace = false

  values = [yamlencode({
    installCRDs = true
    serviceAccount = {
      create = true
      name   = var.eso_service_account
      annotations = {
        ## The role ARN is used to specify the IAM role that the service account can assume.
        "eks.amazonaws.com/role-arn" = module.eso_irsa.iam_role_arn
      }
    }
  })]
}


############################################
# IRSA Role for ESO
############################################
module "eso_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${module.eks.cluster_name}-external-secrets-irsa"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.eso_namespace}:${var.eso_service_account}"]
    }
  }

  role_policy_arns = {
    eso_read = aws_iam_policy.secret_manager_read_access.arn
  }
}

############################################
# IAM Policy
############################################
resource "aws_iam_policy" "secret_manager_read_access" {
  name        = "${module.eks.cluster_name}-eso-access"
  description = "Allow ESO to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadDocDBSecrets"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = var.secret_arns
    }]
  })
}

