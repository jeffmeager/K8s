resource "aws_secretsmanager_secret" "mongo_db_username" {
  name        = "mongo-db-username"
  description = "MongoDB admin username"
}

resource "aws_secretsmanager_secret_version" "mongo_db_username_version" {
  secret_id     = aws_secretsmanager_secret.mongo_db_username.id
  secret_string = var.mongo_db_username
}

resource "aws_secretsmanager_secret" "mongo_db_password" {
  name        = "mongo-db-password"
  description = "MongoDB admin password"
}

resource "aws_secretsmanager_secret_version" "mongo_db_password_version" {
  secret_id     = aws_secretsmanager_secret.mongo_db_password.id
  secret_string = var.mongo_db_password
}