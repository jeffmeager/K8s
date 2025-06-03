provider "aws" {
  region  = "ap-southeast-2"
}

// Ensure to define you're own bucket
variable "state_bucket" {
  description = "S3 bucket used to store terraform state to allow for destroy pipeline"
  type        = string
  default     = "jeffmeager-challenge-terraform-state-bucket"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
