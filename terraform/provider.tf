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