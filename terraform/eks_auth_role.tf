# Define the EKS Admin Role
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::559050241687:user/Jeff"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-admin-role"
  }
}

# Attach core EKS policies

resource "aws_iam_role_policy_attachment" "eks_admin_cluster_policy_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_admin_service_policy_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Optional: CloudWatch Logs access for viewing EKS logs

resource "aws_iam_role_policy_attachment" "eks_admin_cloudwatch_logs_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Optional: SSM Session Manager access to EKS nodes

resource "aws_iam_role_policy_attachment" "eks_admin_ssm_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
