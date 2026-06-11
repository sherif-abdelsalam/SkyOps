terraform {
  backend "s3" {
    bucket       = "sherif-terraform-state-bucket"
    key          = "skyops-terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}