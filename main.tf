provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# S3 Bucket for Lambda backend storage
resource "aws_s3_bucket" "lambda_backend" {
  bucket = "${var.project_name}-backend-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "lambda_backend_versioning" {
  bucket = aws_s3_bucket.lambda_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}