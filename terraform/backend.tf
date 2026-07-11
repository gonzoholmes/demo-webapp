terraform {
  backend "s3" {
    bucket       = "s3-bucket-gholmes8585-demowebapp-tfstate"
    key          = "wizlab/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
