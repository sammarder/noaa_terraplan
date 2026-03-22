terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest stable version
    }
  }
}



data "aws_caller_identity" "current" {}

module "network" {
  source              = "./modules/vpc"
  region          = var.region
}