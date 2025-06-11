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
    mongodb-uri = "mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_instance.mongodb_instance.public_ip}:27017"
    secret-key  = random_password.secret_key.result
  })

  depends_on = [
    aws_instance.mongodb_instance
  ]
}

resource "kubernetes_secret" "webapp_secrets" {
  metadata {
    name      = "webapp-secrets"
    namespace = "default"
  }

  data = {
    mongodb-uri = base64encode("mongodb://${var.mongodb_username}:${var.mongodb_password}@${aws_instance.mongodb_instance.public_ip}:27017")
    secret-key  = base64encode(random_password.secret_key.result)
  }

  type = "Opaque"

  depends_on = [
    aws_instance.mongodb_instance,
    aws_secretsmanager_secret_version.webapp_secrets_version
  ]
}
