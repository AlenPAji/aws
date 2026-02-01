terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

resource "aws_s3_bucket" "bucket" {
  bucket = "policy-only-bucket-123456"
  
  tags = {
    Name        = "Policy Only Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = file("${path.module}/policy.json")
}