resource "kubernetes_config_map" "aws_auth" {
  count      = var.enable_aws_auth ? 1 : 0
  depends_on = [aws_eks_node_group.node]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat(
        [
          {
            rolearn  = data.aws_eks_node_group.default.node_role_arn
            username = "system:node:{{EC2PrivateDNSName}}"
            groups   = [
              "system:bootstrappers",
              "system:nodes"
            ]
          }
        ],
        [
          for rolearn in var.admin_role_arns : {
            rolearn  = rolearn
            username = "admin"
            groups   = [
              "system:masters"
            ]
          }
        ]
      )
    )
  }

  lifecycle {
    ignore_changes = [
      data["mapRoles"]
    ]
  }
}

