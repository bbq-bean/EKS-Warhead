terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

# Backend must remain commented until the Bucket
# and the DynamoDB table are created. 
# After the creation you can uncomment it,
# run "terraform init" and then "terraform apply" 

# this is because you create the initial TF managed infra with 
# only a local backend and state file, 
# then TF init with a real TF backend like DynamoDB with S3 here
terraform {
   backend "s3" {
     bucket         = "terraform-state-backend-02-28-25-2"
     key            = "terraform.tfstate"
     region         = "us-west-1"
     dynamodb_table = "terraform-lock-02-28-25-2"
   }
 }

resource "aws_dynamodb_table" "terraform_state" {
    name           = "terraform-lock-02-28-25-2"
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        "Name" = "DynamoDB Terraform State Lock Table"
    }
} 

resource "aws_s3_bucket" "backend_bucket" {
  bucket              = "terraform-state-backend-02-28-25-2"
  object_lock_enabled = true

  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_s3_bucket_versioning" "backend_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_encryption" {
  bucket = aws_s3_bucket.backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
