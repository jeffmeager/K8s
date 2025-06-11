# resource "aws_secretsmanager_secret" "mongodb_username" {
#   name        = "mongodb_username"
#   description = "MongoDB admin username"
# }

# resource "aws_secretsmanager_secret_version" "mongodb_username_version" {
#   secret_id     = aws_secretsmanager_secret.mongodb_username.id
#   secret_string = var.mongodb_username
# }

# resource "aws_secretsmanager_secret" "mongodb_password" {
#   name        = "mongodb_password"
#   description = "MongoDB admin password"
# }

# resource "aws_secretsmanager_secret_version" "mongodb_password_version" {
#   secret_id     = aws_secretsmanager_secret.mongodb_password.id
#   secret_string = var.mongodb_password
# }

resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "webapp_secrets" {
  name = "webapp-secrets"
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
