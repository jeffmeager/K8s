terraform {
  backend "s3" {
    bucket         = "jeffmeager-challenge-terraform-state-bucket"
    key            = "wiz-challenge/terraform-aws_auth.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
  }
}

resource "kubernetes_manifest" "aws_auth" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "aws-auth"
      namespace = "kube-system"
    }
    data = {
      mapRoles = yamlencode([
        {
          rolearn  = aws_iam_role.eks_node.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = [
            "system:bootstrappers",
            "system:nodes"
          ]
        },
        {
          rolearn  = "arn:aws:iam::559050241687:role/AWSReservedSSO_AdministratorAccess_69ccaa80db7e44d3"
          username = "admin"
          groups   = [
            "system:masters"
          ]
        }
      ])
    }
  }

  depends_on = [aws_eks_node_group.node]
}
