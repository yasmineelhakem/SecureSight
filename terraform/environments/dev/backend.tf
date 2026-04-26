terraform {
  backend "s3" {
    bucket         = "s3-bucket-securesight-yasmine"
    key            = "securesight/dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
    # profile is read from AWS_PROFILE environment variable
  }
}