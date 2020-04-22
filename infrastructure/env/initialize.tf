provider "aws" {
  region = "us-east-1"
}

## Naming

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "slime-terraform-state"
}

variable "id_rsa_pub" {
  description = "Takes inputed public key to generate a PEM file"
  type        = string
  default     = null
}


# IAM Creation

resource "aws_iam_user" "initialize" {
  name = var.project_name
}

resource "aws_iam_user_policy_attachment" "initialize" {
  user       = aws_iam_user.initialize.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "initialize" {
  user = aws_iam_user.initialize.name
}

output "aws_iam_secret" {
  value = aws_iam_access_key.initialize
}

# DynamoDB

resource "aws_dynamodb_table" "initialize" {
  name           = var.project_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.project_name
  }
}

# S3 Bucket

# S3
resource "aws_s3_bucket" "initialize" {
  bucket        = var.project_name
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags = {
    Name = var.project_name
  }
}

resource "aws_s3_bucket_policy" "initialize" {
  bucket = aws_s3_bucket.initialize.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_user.initialize.arn}"
        ]
      },
      "Action": "s3:*",
      "Resource": "${aws_s3_bucket.initialize.arn}"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "initialize" {
  bucket = aws_s3_bucket.initialize.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create Iam Key Pair

resource "aws_iam_user_ssh_key" "initialize" {
  username   = aws_iam_user.initialize.name
  encoding   = "SSH"
  public_key = var.id_rsa_pub
}

resource "aws_key_pair" "initialize" {
  key_name   = "slime"
  public_key = var.id_rsa_pub
}