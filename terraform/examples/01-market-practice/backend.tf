terraform {
  backend "s3" {
    bucket         = "terraform-state-aws-iac-practices"
    key            = "examples/01-market-practice/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}