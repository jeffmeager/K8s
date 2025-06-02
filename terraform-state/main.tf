provider "aws" {
  region  = "ap-southeast-2"
  profile = "devops-admin"
}

# Try to load the bucket data — this will fail if it doesn't exist,
# but we will handle that gracefully with `can()`
data "aws_s3_bucket" "existing" {
  bucket = "jeffmeager-challenge-terraform-state-bucket"
}

# Only create the bucket if it doesn't already exist (can() handles lookup failure)
resource "aws_s3_bucket" "terraform_state" {
  count  = can(data.aws_s3_bucket.existing.id) ? 0 : 1
  bucket = "jeffmeager-challenge-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

# Only configure versioning if the bucket is newly created
resource "aws_s3_bucket_versioning" "versioning" {
  count  = aws_s3_bucket.terraform_state.count
  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Only apply encryption config if the bucket is newly created
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = aws_s3_bucket.terraform_state.count
  bucket = aws_s3_bucket.terraform_state[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
