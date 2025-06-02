resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound MySQL access from EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Consider restricting this further
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

resource "aws_db_subnet_group" "wordpress_subnet_group" {
  name       = "wordpress-db-subnet-group"

  # Use the private subnet declared in main.tf
  subnet_ids = [aws_subnet.private_az1.id,aws_subnet.private_az2]

  tags = {
    Name = "wordpress-db-subnet-group"
  }
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mariadb"
  engine_version          = "10.6"
  instance_class          = "db.t3.micro"
  identifier              = "wordpress-mariadb"
  db_name                    = "wordpress"
  username                = var.db_username
  password                = var.db_password
  port                    = 3306
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.wordpress_subnet_group.name
  skip_final_snapshot     = true

  tags = {
    Name = "wordpress-db"
  }
}

resource "aws_secretsmanager_secret" "wordpress_db_password" {
  name = "wordpress-db-password"
}

resource "aws_secretsmanager_secret_version" "wordpress_db_password_version" {
  secret_id     = aws_secretsmanager_secret.wordpress_db_password.id
  secret_string = var.db_password
}

