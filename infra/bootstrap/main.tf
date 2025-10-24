# Random suffix for globally-unique bucket names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  number  = true
  special = false
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "project_name" {
  type    = string
  default = "devbook"
}

locals {
  bucket_name = "${var.project_name}-tfstate-${random_string.suffix.result}-${var.region}"
  lock_name   = "${var.project_name}-terraform-locks"
}

# S3 bucket for remote state
resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name
  tags = {
    Name = "${var.project_name}-tfstate"
    Env  = "global"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "locks" {
  name         = local.lock_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute { 
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = local.lock_name
    Env  = "global"
  }
}
