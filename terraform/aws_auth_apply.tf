data "template_file" "aws_auth" {
  template = file("${path.module}/../kubernetes/deployments/aws-auth.yaml.tpl")

  vars = {
    node_role_arn  = aws_eks_node_group.node.node_role_arn
    admin_role_arns = join(",", var.admin_role_arns)
  }
}

resource "local_file" "aws_auth_yaml" {
  content  = data.template_file.aws_auth.rendered
  filename = "${path.module}/../kubernetes/deployments/aws-auth.yaml"
}

resource "null_resource" "aws_auth_apply" {
  depends_on = [aws_eks_node_group.node, local_file.aws_auth_yaml]

  provisioner "local-exec" {
    command = <<EOT
      set -o errexit -o pipefail -o nounset
      echo "🔧 Applying aws-auth ConfigMap..."
      aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.eks.name}
      kubectl apply -f ${path.module}/../kubernetes/deployments/aws-auth.yaml
    EOT
  }
}
