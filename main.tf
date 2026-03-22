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
  kms_key = module.encryption.key_arn
  s3_lambda_arn = module.lambda.preproc_arn
  lambda_allow = module.lambda.permission_id
}

module "lambda" {
  source = "./modules/compute/lambda"
  lambda_role = module.permission.lambda_role
  pipeline_arn = module.orchestration.pipeline_arn
  bucket_arn = module.storage.bucket_arn
  script_location = "${path.module}/scripts/"
}

module "permission" {
  source = "./modules/permission"
  key_arn = module.encryption.key_arn
  glue_crawler = module.etl.noaa_crawler_arn
  glue_job = module.etl.noaa_glue_etl_arn
  analyst_account = aws_organizations_account.analyst_account.id
  bucket = module.storage.bucket_arn
  archiver_arn = module.lambda.archiver_arn
  caller_identity = data.aws_caller_identity.current.account_id
  region = var.region
}

module "encryption" {
  source = "./modules/encryption"
  caller_identity = data.aws_caller_identity.current.account_id
}

module "orchestration" {
  source = "./modules/compute/orchestration"
  glue_job = module.etl.noaa_glue_etl_name
  bucket = module.storage.bucket_id
  archiver_arn = module.lambda.archiver_arn
  sf_permission = module.permission.sf_role
  crawler_name = module.etl.noaa_glue_crawler_name
}

module "etl" {
  source = "./modules/compute/etl"
  glue_etl_role = module.permission.glue_proc_role
  bucket = module.storage.bucket_id
  connector_name = module.network.glue_connector_name
  root_dir = path.module
  crawler_role = module.permission.glue_crawler_role
}