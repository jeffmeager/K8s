locals {
  aws_auth_yaml = templatefile("${path.module}/../kubernetes/deployments/aws-auth.yaml.tpl", {
    node_role_arn   = aws_eks_node_group.node.node_role_arn
    admin_role_arns = var.admin_role_arn
  })
}

resource "local_file" "aws_auth_yaml" {
  content              = local.aws_auth_yaml
  filename             = "${path.module}/../kubernetes/deployments/aws-auth.yaml"
  file_permission      = "0777"
  directory_permission = "0777"
}

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
