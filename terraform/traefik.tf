resource "kubernetes_namespace" "traefik_ns" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "26.1.0"

  set {
    name  = "ports.websecure.expose"
    value = false
  }

  set {
    name  = "ports.websecure.tls.enabled"
    value = false
  }
}

resource "kubernetes_service_account" "traefik_sa" {
  metadata {
    name      = "traefik-account"
    namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "traefik_cr" {
  metadata {
    name = "traefik-role"
  }

  rule {
    api_groups = [""]
    resources  = [
      "services",
      "endpoints",
      "secrets",
      "tlsstores",
      "ingressroutes",
      "ingressroutetcps",
      "ingressrouteudps",
      "middlewares",
      "tlsstores",
      "middlewaretcps",
      "tlsoptions",
      "tlsstores",
      "traefikservices",
      "serverstransports",
      "ingresses/status",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io", "traefik.containo.us", "traefik.io"]
    resources  = [
      "services",
      "endpoints",
      "secrets",
      "tlsstores",
      "ingresses",
      "ingressclasses",
      "ingressroutes",
      "ingressroutetcps",
      "ingressrouteudps",
      "middlewares",
      "tlsstores",
      "middlewaretcps",
      "tlsoptions",
      "tlsstores",
      "traefikservices",
      "serverstransports",
      "ingresses/status",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik_crb" {
  metadata {
    name = "traefik-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.traefik_cr.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.traefik_sa.metadata[0].name
    namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  }
}

resource "kubernetes_deployment" "traefik_deployment" {
  metadata {
    name = "traefik-deployment"
    labels = {
      app = "traefik"
    }
    namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.traefik_sa.metadata[0].name

        container {
          name  = "traefik"
          image = "traefik:v2.11"

          args = [
            "--api.insecure",
            "--providers.kubernetesingress",
            "--providers.kubernetescrd=true",
            "--providers.kubernetescrd.namespaces=dev",
          ]

          port {
            name        = "web"
            container_port = 80
          }

          port {
            name        = "dashboard"
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "traefik_services" {
  metadata {
    name      = "traefik-dashboard-service"
    namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  }

  spec {
    type = "ClusterIP" # temporary

    selector = {
      app = "traefik"
    }

    port {
      port        =  3000
      target_port = "dashboard"
    }
  }
}

resource "kubernetes_service" "traefik_web_service" {
  metadata {
    name      = "traefik-web-service"
    namespace = kubernetes_namespace.traefik_ns.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "traefik"
    }

    port {
      port        = 80
      target_port = "web"
    }
  }
}