terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "eu-west-3"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}