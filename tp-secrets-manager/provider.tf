terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "eu-west-3"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
  s3             = "http://localhost:4566"
  iam            = "http://localhost:4566"
  lambda         = "http://localhost:4566"
  secretsmanager = "http://localhost:4566"
}
}
