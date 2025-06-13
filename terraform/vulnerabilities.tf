# -----------------------------------------------------------------------------------
# Overly permissive EKS Cluster role

resource "aws_iam_role_policy_attachment" "eks_cluster_AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.eks.name
}

# Overly permissive EKS Node Group role
resource "aws_iam_role_policy_attachment" "eks_node_AdministratorAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.eks_node.name
}

# -----------------------------------------------------------------------------------
# Turn of S3 bucket protections

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.backup_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------------------------------------------------------------
# Public bucket policy

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = aws_s3_bucket.backup_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.backup_bucket.arn}/*"
      }
    ]
  })
  depends_on = [
    aws_s3_bucket_public_access_block.block_public_access
  ]
}

# -----------------------------------------------------------------------------------
# IAM Role for MongoDB host

resource "aws_iam_role" "mongodb_instance_role" {
  name = "mongodb-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "Challenge"
  }
}

# -----------------------------------------------------------------------------------
# Attach overly permissive policy to role

resource "aws_iam_role_policy_attachment" "mongodb_instance_role_attach" {
  role       = aws_iam_role.mongodb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# -----------------------------------------------------------------------------------
# Instance profile to use role for Mongodb

resource "aws_iam_instance_profile" "mongodb_instance_profile" {
  name = "mongodb-instance-profile"
  role = aws_iam_role.mongodb_instance_role.name
}