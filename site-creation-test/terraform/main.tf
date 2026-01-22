provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "site_automation" {
  metadata {
    name = "site-automation"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend-deployment"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "backend"
          image = "backend:latest"
          port {
            container_port = 8000
          }
          env_from {
            config_map_ref {
              name = "backend-config"
            }
          }
          volume_mount {
            name       = "backend-volume"
            mount_path = "/app"
          }
        }
        volume {
          name = "backend-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend-service"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      protocol    = "TCP"
      port        = 8000
      target_port = 8000
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend-deployment"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {
        container {
          name  = "frontend"
          image = "frontend:latest"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = "frontend-config"
            }
          }
          volume_mount {
            name       = "frontend-volume"
            mount_path = "/app"
          }
        }
        volume {
          name = "frontend-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend-service"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    selector = {
      app = "frontend"
    }
    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-deployment"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:13"
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_USER"
            value = "user"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
          env {
            name  = "POSTGRES_DB"
            value = "site_automation"
          }
          volume_mount {
            name       = "postgres-volume"
            mount_path = "/var/lib/postgresql/data"
          }
        }
        volume {
          name = "postgres-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  spec {
    selector = {
      app = "postgres"
    }
    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_config_map" "backend" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  data = {
    DATABASE_URL                  = "postgresql://user:password@postgres-service:5432/site_automation"
    SECRET_KEY                    = "your_secret_key"
    ALGORITHM                     = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES   = "30"
  }
}

resource "kubernetes_config_map" "frontend" {
  metadata {
    name      = "frontend-config"
    namespace = kubernetes_namespace.site_automation.metadata[0].name
  }
  data = {
    REACT_APP_API_URL = "http://backend-service:8000"
  }
}