resource "kubernetes_namespace" "argo_ns" {
  metadata {
    name = "argo"
  }
}

resource "helm_release" "argo_cd" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
    namespace  = "argo"

  set {
    name  = "configs.cm.timeout.reconciliation"
    value = "30s"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value =  bcrypt(var.argocd_password, 10)
  }
}

resource "helm_release" "argo_rollouts" {
  name = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  namespace  = "argo"

  set {
    name  = "dashboard.enabled"
    value = true
  }
}