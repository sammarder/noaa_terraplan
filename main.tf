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

module "storage" {
  source = "./modules/storage"
  kms_key = aws_kms_key.noaa_key.arn
  s3_lambda_arn = module.lambda.preproc_arn
  lambda_allow = module.lambda.permission_id
}

module "lambda" {
  source = "./modules/compute/lambda"
  lambda_role = aws_iam_role.lambda_role.arn
  pipeline_arn = aws_sfn_state_machine.noaa_pipeline.arn
  bucket_arn = module.storage.bucket_arn
  script_location = "${path.module}/scripts/"
}