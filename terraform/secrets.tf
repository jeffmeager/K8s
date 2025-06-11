resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "webapp_secrets" {
  name        = "webapp-secrets"
  description = "Secrets for WebApp (MONGODB_URI and SECRET_KEY)"
}

resource "aws_secretsmanager_secret_version" "webapp_secrets_version" {
  secret_id = aws_secretsmanager_secret.webapp_secrets.id

  secret_string = jsonencode({
    mongodb-uri = "mongodb://${var.mongodb_username}:${urlencode(var.mongodb_password)}@${aws_instance.mongodb_instance.public_ip}:27017/admin"
    secret-key  = random_password.secret_key.result
  })

  depends_on = [
    aws_instance.mongodb_instance
  ]
}

resource "null_resource" "wait_for_cluster_ready" {
  depends_on = [null_resource.aws_auth_apply]

  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Waiting for EKS API server to be ready..."
      for i in {1..10}; do
        if kubectl get nodes >/dev/null 2>&1; then
          echo "✅ EKS API server is ready."
          exit 0
        fi
        echo "⏳ Still waiting... ($i/10)"
        sleep 10
      done
      echo "❌ Timeout waiting for EKS API server."
      exit 1
    EOT
  }
}

resource "kubernetes_secret" "webapp_secrets" {
  metadata {
    name      = "webapp-secrets"
    namespace = "default"
  }

  data = {
    mongodb-uri = "mongodb://${var.mongodb_username}:${urlencode(var.mongodb_password)}@${aws_instance.mongodb_instance.public_ip}:27017"

    secret-key  = random_password.secret_key.result
  }

  type = "Opaque"

  depends_on = [
    aws_instance.mongodb_instance,
    aws_secretsmanager_secret_version.webapp_secrets_version,
    null_resource.wait_for_cluster_ready
  ]
}
