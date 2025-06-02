data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [aws_eks_node_group.node]

  metadata {
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
