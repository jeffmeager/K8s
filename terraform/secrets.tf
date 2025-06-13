resource "aws_secretsmanager_secret" "webapp_secrets" {
  name        = "webapp-secrets"
  description = "Secrets for WebApp (MONGODB_URI and SECRET_KEY)"
}

resource "aws_secretsmanager_secret_version" "webapp_secrets_version" {
  secret_id = aws_secretsmanager_secret.webapp_secrets.id

  secret_string = jsonencode({
    mongodb-uri = "mongodb://${var.mongodb_username}:${urlencode(var.mongodb_password)}@${aws_instance.mongodb_instance.private_ip}:27017/admin"
    secret-key  = var.mongodb_secret_key
  })

  depends_on = [
    aws_instance.mongodb_instance
  ]
}
