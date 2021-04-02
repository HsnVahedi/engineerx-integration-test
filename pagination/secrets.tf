resource "kubernetes_secret" "postgres_password" {
  metadata {
    name      = "postgres-password-${var.test_name}-${var.test_number}"
    namespace = "integration-test"
    labels = {
      role = "integration"
    }
  }

  data = {
    password = "777kkdo##$%%!!kdkdkd"
  }
}

resource "kubernetes_secret" "django_secret_key" {
  metadata {
    name = "django-secret-key-${var.test_name}-${var.test_number}"
    namespace = "integration-test"
    labels = {
      role = "integration"
    }
  }

  data = {
    secret_key = "lksd;flkjasd;lfkajdfhuqkl4848400nvc" 
  }
}

resource "kubernetes_secret" "dockerhub_cred" {
  metadata {
    name = "dockerhub-cred-${var.test_name}-${var.test_number}"
    namespace = "integration-test"
    labels = {
      role = "integration"
    }
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "${base64encode("${var.dockerhub_username}:${var.dockerhub_password}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}