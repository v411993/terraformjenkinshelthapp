provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "aws-dev-infrastructure"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
