provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "shan-ali-terraform-state" {
  bucket = "shan-ali-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "shan-ali-terraform-state-versioning" {
  bucket = aws_s3_bucket.shan-ali-terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "shan-ali-terraform-state-encryption-config" {
  bucket = aws_s3_bucket.shan-ali-terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
