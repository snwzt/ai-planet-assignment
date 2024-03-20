resource "kubernetes_namespace" "argo_ns" {
  metadata {
    name = "argo"
  }
}

resource "helm_release" "argo" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argo"
  version    = "6.5.0"

  set {
    name  = "configs.cm.timeout.reconciliation"
    value = "30s"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value =  bcrypt(var.argocd_password, 10)
  }
}