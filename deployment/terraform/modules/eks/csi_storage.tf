data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}


data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ebs_csi" {
  name = "ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.61.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_node_group.general,
    aws_iam_role.ebs_csi
  ]
}

# # resource "kubernetes_storage_class_v1" "gp2" {
# #   metadata {
# #     name = "gp2"
# #     annotations = {
# #       "storageclass.kubernetes.io/is-default-class" = "true"
# #     }
# #   }

# #   storage_provisioner = "ebs.csi.aws.com"

# #   volume_binding_mode = "WaitForFirstConsumer"
# #   reclaim_policy      = "Retain"

# #   parameters = {
# #     type = "gp2"
# #   }

# #   depends_on = [aws_eks_addon.ebs_csi]
# # }