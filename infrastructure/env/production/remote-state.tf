terraform {
  backend "s3" {
    bucket         = "slime-terraform-state"
    encrypt        = true
    dynamodb_table = "slime-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
  }
}
