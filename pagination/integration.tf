resource "kubernetes_pod" "integration" {
  metadata {
    name      = "integration-${var.test_name}-${var.test_number}"
    namespace = "integration-test"

    labels = {
      app  = "integration"
      role = "integration"
    }
  }

  spec {
    volume {
      name = "data"
    }

    container {
      name    = "cypress"
      image   = "hsndocker/integration-cypress:latest"
      command = ["/bin/bash", "-c", "sleep infinity"]

      resources {
        limits = {
          cpu    = "1200m"
          memory = "1024Mi"
        }

        requests = {
          memory = "1024Mi"
          cpu    = "700m"
        }
      }
    }
    container {
      name    = "frontend"
      image   = "hsndocker/frontend:${var.frontend_version}"
      command = ["/bin/sh", "-c", "npm run build && npm run start"]

      port {
        container_port = 3000
      }

      resources {
        limits = {
          cpu    = "1200m"
          memory = "1024Mi"
        }

        requests = {
          memory = "1024Mi"
          cpu    = "700m"
        }
      }

      env {
        name  = "INTEGRATION_TEST"
        value = "1"
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = "3000"
        }

        initial_delay_seconds = 100
        period_seconds        = 5
      }

      readiness_probe {
        http_get {
          path = "/health"
          port = "3000"
        }

        initial_delay_seconds = 120
        period_seconds        = 5
      }

    }
    container {
      name  = "nginx"
      image = "hsndocker/backend-integration-nginx:${var.backend_version}"

      port {
        container_port = 8001
      }

      resources {
        limits = {
          cpu    = "100m"
          memory = "64Mi"
        }

        requests = {
          memory = "64Mi"
          cpu    = "100m"
        }
      }

      volume_mount {
        name       = "data"
        mount_path = "/home/app/web/static"
        sub_path   = "static"
      }

      volume_mount {
        name       = "data"
        mount_path = "/home/app/web/media"
        sub_path   = "media"
      }

    }
    container {
      name    = "backend"
      image   = "hsndocker/backend:${var.backend_version}"
      command = ["/bin/bash", "-c", "rm manage.py && mv manage.integration.py manage.py && rm engineerx/wsgi.py && mv engineerx/wsgi.integration.py engineerx/wsgi.py && ./start.sh"]

      port {
        container_port = 8000
      }

      env {
        name = "POSTGRES_PASSWORD"

        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres_password.metadata[0].name
            key  = "password"
          }
        }
      }

      env {
        name = "SECRET_KEY"

        value_from {
          secret_key_ref {
            name = kubernetes_secret.django_secret_key.metadata[0].name
            key  = "secret_key"
          }
        }
      }

      env {
        name  = "FRONTEND_URL"
        value = "http://localhost:3000"
      }

      env {
        name  = "ALLOWED_HOST"
        value = "*"
      }

      env {
        name  = "INITDB_USERS_SIZE"
        value = 50
      }

      env {
        name  = "INITDB_EDITORS_SIZE"
        value = 50
      }

      env {
        name  = "INITDB_MODERATORS_SIZE"
        value = 50
      } 

      env {
        name  = "INITDB_POSTS_SIZE"
        value = 100
      }

      resources {
        limits = {
          cpu    = "1200m"
          memory = "1024Mi"
        }

        requests = {
          memory = "512Mi"
          cpu    = "700m"
        }
      }

      volume_mount {
        name       = "data"
        mount_path = "/app/static"
        sub_path   = "static"
      }

      volume_mount {
        name       = "data"
        mount_path = "/app/media"
        sub_path   = "media"
      }

      liveness_probe {
        http_get {
          path = "/"
          port = "8000"
        }

        initial_delay_seconds = 60
        period_seconds        = 10
      }

      readiness_probe {
        http_get {
          path = "/"
          port = "8000"
        }

        initial_delay_seconds = 100
        period_seconds        = 10
      }

    }
    container {
      name  = "postgres"
      image = "hsndocker/backend-postgres:${var.backend_version}"

      port {
        container_port = 5432
      }

      env {
        name = "POSTGRES_PASSWORD"

        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres_password.metadata[0].name
            key  = "password"
          }
        }
      }

      volume_mount {
        name       = "data"
        mount_path = "/var/lib/postgresql/data"
        sub_path   = "postgres"
      }

      resources {
        limits = {
          cpu    = "300m"
          memory = "1024Mi"
        }

        requests = {
          memory = "512Mi"
          cpu    = "200m"
        }
      }

    }
    
    image_pull_secrets {
      name = kubernetes_secret.dockerhub_cred.metadata[0].name
    }
  }
}
