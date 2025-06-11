provider "aws" {
  region  = var.region
}

// Used for generating the secret key
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = aws_eks_cluster.eks_cluster.arn
}
