terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest stable version
    }
  }
}

locals {
  caller_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn
  glue_crawler = var.glue_crawler
  glue_job = var.glue_job
  bucket = var.bucket
  archiver = var.archiver
  region = var.region
}

data "aws_caller_identity" "current" {}

module "network" {
  source              = "./modules/network"
  region          = local.region
}

module "encryption" {
  source = "./modules/encryption"
  caller_identity = data.aws_caller_identity.current.account_id
}

module "storage" {
  source = "./modules/storage"
  kms_key = module.encryption.key_arn
  s3_lambda_arn = module.lambda.preproc_arn
  lambda_allow = module.lambda.permission_id
  bucket_name = local.bucket
}

module "lambda" {
  source = "./modules/compute/lambda"
  lambda_role = module.permission.role_arns.lambda
  pipeline_arn = module.orchestration.pipeline_arn
  bucket_arn = module.storage.bucket_details.arn
  script_location = "${path.module}/scripts/"
  archiver = local.archiver
}

module "orchestration" {
  source = "./modules/compute/orchestration"
  glue_job = module.etl.noaa_glue_etl_name
  bucket = module.storage.bucket_details.id
  archiver_arn = module.lambda.archiver_arn
  sf_permission = module.permission.role_arns.step_function
  crawler_name = module.etl.noaa_glue_crawler_name
}

module "etl" {
  source = "./modules/compute/etl"
  glue_etl_role = module.permission.role_arns.glue_process
  bucket = module.storage.bucket_details.id
  connector_name = module.network.glue_connector_name
  root_dir = path.module
  crawler_role = module.permission.role_arns.glue_crawler
  job_name = local.glue_job
  crawler_name = local.glue_crawler
}

module "permission" {
  source = "./modules/permission"
  key_arn = module.encryption.key_arn
  glue_crawler = local.glue_crawler
  glue_job = local.glue_job
  analyst_account = aws_organizations_account.analyst_account.id
  bucket = local.bucket
  archiver = local.archiver
  caller_identity = local.caller_id
  region = local.region
}
module "lake" {
  source = "./modules/permission/lake"
  caller_arn = local.caller_arn
  glue_proc_role = module.permission.role_arns.glue_process
  bucket = module.storage.bucket_details
  glue_crawler_role = module.permission.role_arns.glue_crawler
  noaa_catalog_db_name = module.etl.noaa_catalog_db_name
}