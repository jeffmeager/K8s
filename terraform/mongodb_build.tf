resource "aws_instance" "mongodb_instance" {
  ami                         = "ami-055744c75048d8296"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.mongodb_sg.id]

  iam_instance_profile = aws_iam_instance_profile.mongodb_instance_profile.name

  user_data = templatefile("${path.module}/userdata/mongodb-user-data.sh", {
    mongodb_username = var.mongodb_username
    mongodb_password = var.mongodb_password
    backup_bucket    = aws_s3_bucket.backup_bucket.bucket
  })

  depends_on = [aws_s3_bucket.backup_bucket]
  
  tags = {
      Name = "Challenge"
    }
}