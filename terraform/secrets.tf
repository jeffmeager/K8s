resource "aws_secretsmanager_secret" "mongodb_username" {
  name        = "mongodb_username"
  description = "MongoDB admin username"
}

resource "aws_secretsmanager_secret_version" "mongodb_username_version" {
  secret_id     = aws_secretsmanager_secret.mongodb_username.id
  secret_string = var.mongodb_username
}

resource "aws_secretsmanager_secret" "mongodb_password" {
  name        = "mongodb_password"
  description = "MongoDB admin password"
}

resource "aws_secretsmanager_secret_version" "mongodb_password_version" {
  secret_id     = aws_secretsmanager_secret.mongodb_password.id
  secret_string = var.mongodb_password
}