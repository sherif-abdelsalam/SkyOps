resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

  resource "helm_release" "ingress_nginx" {
    name       = "ingress-nginx"
    repository = "https://kubernetes.github.io/ingress-nginx"
    chart      = "ingress-nginx"
    version    = var.ingress_nginx_version # defined in variables.tf
    namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name

    # Wait until controller pod is fully Running
    # before Terraform marks this as done
    wait    = true
    timeout = 300
    set = [
      {
        name  = "controller.service.type"
        value = "LoadBalancer"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
      },

      {
        name  = "controller.ingressClassResource.default"
        value = "true"
      },

      {
        name  = "controller.ingressClassResource.name"
        value = "nginx"
      },
      {
        name  = "controller.config.use-forwarded-headers"
        value = "true"
      },

      {
        name  = "controller.replicaCount"
        value = "1"
      }
    ]


    depends_on = [kubernetes_namespace_v1.ingress_nginx]
  }




data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}



output "nlb_dns" {
  description = "NLB DNS hostname"
  value = data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
}