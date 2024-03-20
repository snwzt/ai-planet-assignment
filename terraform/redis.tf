resource "kubernetes_manifest" "storageclass_local_storage" {
  manifest = {
    "allowVolumeExpansion" = true
    "apiVersion" = "storage.k8s.io/v1"
    "kind" = "StorageClass"
    "metadata" = {
      "name" = "local-storage"
    }
    "provisioner" = "kubernetes.io/no-provisioner"
    "reclaimPolicy" = "Delete"
    "volumeBindingMode" = "WaitForFirstConsumer"
  }
}

resource "kubernetes_manifest" "persistentvolume_local_pv" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolume"
    "metadata" = {
      "name" = "local-pv"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "capacity" = {
        "storage" = "1Gi"
      }
      "hostPath" = {
        "path" = "/storage/data"
      }
      "storageClassName" = "local-storage"
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_dev_redis_pvc" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "name" = "redis-pvc"
      "namespace" = "dev"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "1Gi"
        }
      }
      "storageClassName" = "local-storage"
    }
  }
}

resource "kubernetes_manifest" "service_dev_redis_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "redis-service"
      "namespace" = "dev"
    }
    "spec" = {
      "clusterIP" = "None"
      "ports" = [
        {
          "name" = "redis"
          "port" = 6379
        },
      ]
      "selector" = {
        "app" = "redis"
      }
    }
  }
}

resource "kubernetes_manifest" "statefulset_dev_redis" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "StatefulSet"
    "metadata" = {
      "name" = "redis"
      "namespace" = "dev"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "redis"
        }
      }
      "serviceName" = "redis-service"
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "redis"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "redis:latest"
              "name" = "redis"
              "ports" = [
                {
                  "containerPort" = 6379
                  "name" = "redis"
                },
              ]
              "volumeMounts" = [
                {
                  "mountPath" = "/data"
                  "name" = "redis-data"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name" = "redis-data"
              "persistentVolumeClaim" = {
                "claimName" = "redis-pvc"
              }
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "networkpolicy_dev_redis_access" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "NetworkPolicy"
    "metadata" = {
      "name" = "redis-access"
      "namespace" = "dev"
    }
    "spec" = {
      "ingress" = [
        {
          "from" = [
            {
              "podSelector" = {}
            },
          ]
        },
      ]
      "podSelector" = {
        "matchLabels" = {
          "app" = "redis"
        }
      }
      "policyTypes" = [
        "Ingress",
      ]
    }
  }
}