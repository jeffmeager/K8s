# --------------------------------------------------------------------------------
# EKS Admin Role - intended to be assumed manually by SSO user/group.
# No policies attached — permissions are granted via the caller.
# The role is used in aws-auth ConfigMap to give Kubernetes 'system:masters' access.
# --------------------------------------------------------------------------------

resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Initially allow AWS Account root — so you can assign SSO users/groups manually later.
          AWS = "arn:aws:iam::559050241687:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "eks-admin-role"
  }
}

# --------------------------------------------------------------------------------
# Note:
# We intentionally do NOT attach any AWS managed policy here.
# The SSO user/group who assumes this role should have permissions to:
# - Assume this role (sts:AssumeRole)
# - Manage EKS clusters via their own identity permissions.
#
# The eks-admin-role will appear in the aws-auth ConfigMap mapped to system:masters.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local variable to render aws-auth.yaml from template
# --------------------------------------------------------------------------------

locals {
  aws_auth_yaml = templatefile("${path.module}/../kubernetes/deployments/aws-auth.yaml.tpl", {
    node_role_arn      = aws_eks_node_group.node.node_role_arn
    eks_admin_role_arn = aws_iam_role.eks_admin_role.arn
  })
}

# --------------------------------------------------------------------------------
# Write aws-auth.yaml to file
# --------------------------------------------------------------------------------

resource "local_file" "aws_auth_yaml" {
  content              = local.aws_auth_yaml
  filename             = "${path.module}/../kubernetes/deployments/aws-auth.yaml"
  file_permission      = "0777"
  directory_permission = "0777"
}

# --------------------------------------------------------------------------------
# Apply aws-auth ConfigMap to EKS cluster
# --------------------------------------------------------------------------------

resource "null_resource" "aws_auth_apply" {
  depends_on = [aws_eks_node_group.node, local_file.aws_auth_yaml]

  provisioner "local-exec" {
    command = <<EOT
      set -o errexit -o pipefail -o nounset
      echo "🔧 Refreshing kubeconfig..."
      aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.eks.name}

      echo "🔧 Applying aws-auth ConfigMap..."
      kubectl apply -f ${path.module}/../kubernetes/deployments/aws-auth.yaml
    EOT
  }
}
