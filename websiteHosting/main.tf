terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "website" {
  bucket = "my-static-website-899673281289"

  tags = {
    Name        = "Static Website"
    Environment = "Dev"
  }
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Allow public access via policy (NOT ACLs)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Attach bucket policy
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.website.id
  policy = file("${path.module}/policy.json")
  
  # Ensure public access block is configured first
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}
