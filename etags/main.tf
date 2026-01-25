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

resource "aws_s3_bucket" "default" {


 
}
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.default.id
  key    = "my_file.txt"
  source = "my_file.txt"

}