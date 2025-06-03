data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "jeffmeager-challenge-terraform-state-bucket"
    key    = "wiz-challenge/terraform.tfstate"  # <-- Path to phase 1 state
    region = "ap-southeast-2"
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
          rolearn  = data.terraform_remote_state.eks.outputs.eks_node_role_arn
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
}
