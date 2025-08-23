terraform {
  backend "s3" {
    bucket         = "terraform-state-aws-iac-practices"
    key            = "examples/03-market-practice/terraform.tfstate"
    region         = "ap-southeast-1"
    use_lockfile   = true
    encrypt        = true
  }
}