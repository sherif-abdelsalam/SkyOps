############################################
# Namespaces
############################################
resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = var.eso_namespace # e.g., "ghost-secrets"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace # e.g., "app-gamma"
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
# # OIDC Provider
# ############################################
# resource "aws_iam_openid_connect_provider" "eks" {
#     ## url is used for proving that the OIDC provider is trusted by AWS. 
#     ## It is usually in the format of "https://oidc.eks.<region>.amazonaws.com/id/<eks-cluster-id>"
#   url             = module.eks.cluster_oidc_issuer_url
#   ## The client ID list is used to specify the audience that can use the OIDC provider.
#   client_id_list  = ["sts.amazonaws.com"]
#   ## The thumbprint list is used to verify the SSL certificate of the OIDC provider.
#   thumbprint_list = [module.eks.cluster_tls_certificate_sha1_fingerprint]
# }

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


#####################
############################################
# ClusterSecretStore -> AWS Secrets Manager
############################################
resource "kubernetes_manifest" "cluster_secret_store" {
  count = var.enable_external_secrets_crds ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata   = { name = "aws-secrets" }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.eso_service_account
                namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}


############################################
# ExternalSecret -> sync db creds into app ns
############################################
resource "kubernetes_manifest" "db_auth_external_secret" {
  count = var.enable_external_secrets_crds ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"

    metadata = {
      name      = "skyops-db-auth"
      namespace = kubernetes_namespace_v1.app.metadata[0].name
    }

    spec = {
      refreshInterval = "1h"

      secretStoreRef = {
        name = "aws-secrets"
        kind = "ClusterSecretStore"
      }

      target = {
        name           = "skyops-db-auth"
        creationPolicy = "Owner"
      }

      data = [
        {
          secretKey = "auth-password"
          remoteRef = {
            key = "skyops-dev/auth-password"
          }
        },
        {
          secretKey = "root-password"
          remoteRef = {
            key = "skyops-dev/root-password"
          },
        },
        {
          secretKey = "apikey"
          remoteRef = {
            key = "skyops-dev/apikey"
          }
        },
        {
          secretKey = "secret-key"
          remoteRef = {
            key = "skyops-dev/secret-key"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.cluster_secret_store]
}
