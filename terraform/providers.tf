provider "aws" {
  region = var.aws_region

  # Plan-only setup: no real AWS account is needed.
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}