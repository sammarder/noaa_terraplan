resource "aws_ssm_parameter" "bucket_arn" {
  name        = "/noaa/s3/bucket_arn"
  description = "The ARN for the NOAA test bucket"
  type        = "String"
  value       = module.storage.bucket_arn
}

resource "aws_ssm_parameter" "bucket_name" {
  name        = "/noaa/s3/bucket_name"
  description = "The name for the NOAA test bucket"
  type        = "String"
  value       = module.storage.bucket_id
}

resource "aws_ssm_parameter" "key_arn" {
  name        = "/noaa/kms/key_arn"
  description = "The ARN for the NOAA kms key"
  type        = "String"
  value       = module.encryption.key_arn
}

resource "aws_ssm_parameter" "iam_lambda_arn" {
  name        = "/noaa/iam_role/lambda_arn"
  description = "The ARN for the NOAA Lambda IAM role"
  type        = "String"
  value       = module.permission.lambda_role
}

resource "aws_ssm_parameter" "iam_glue_arn" {
  name        = "/noaa/iam_role/glue_arn"
  description = "The ARN for the NOAA Glue Job IAM role"
  type        = "String"
  value       = module.permission.glue_proc_role
}

resource "aws_ssm_parameter" "iam_glue_crawler_arn" {
  name        = "/noaa/iam_role/glue_crawler_arn"
  description = "The ARN for the NOAA Glue Crawler IAM role"
  type        = "String"
  value       = module.permission.glue_crawler_role
}

resource "aws_ssm_parameter" "lambda_preproc_arn" {
  name        = "/noaa/lambda/preprocessor_arn"
  description = "The ARN for the NOAA Preprocessor Lambda Function"
  type        = "String"
  value       = module.lambda.preproc_arn
}

resource "aws_ssm_parameter" "lambda_archive_arn" {
  name        = "/noaa/lambda/archiver_arn"
  description = "The ARN for the NOAA Archiver Lambda Function"
  type        = "String"
  value       = module.lambda.archiver_arn
}

resource "aws_ssm_parameter" "glue_catalog_arn" {
  name        = "/noaa/glue/catalog_arn"
  description = "The ARN for the NOAA Glue Catalog DB"
  type        = "String"
  value       = aws_glue_catalog_database.noaa_db.arn
}

resource "aws_ssm_parameter" "glue_job_arn" {
  name        = "/noaa/glue/job_arn"
  description = "The ARN for the NOAA Glue Job"
  type        = "String"
  value       = aws_glue_job.jsonl_to_parquet.arn
}

resource "aws_ssm_parameter" "glue_crawler_arn" {
  name        = "/noaa/glue/crawler_arn"
  description = "The ARN for the NOAA Glue Crawler"
  type        = "String"
  value       = aws_glue_crawler.noaa_parquet_crawler.arn
}

resource "aws_ssm_parameter" "secondary_account_id" {
  name        = "/noaa/org/org_id"
  description = "The ARN for the NOAA Analyst Account"
  type        = "String"
  value       = aws_organizations_account.analyst_account.id
}

resource "aws_ssm_parameter" "glue_job_name" {
  name        = "/noaa/glue/job_name"
  description = "The Name for the NOAA Glue Job"
  type        = "String"
  value       = aws_glue_job.jsonl_to_parquet.name
}

resource "aws_ssm_parameter" "glue_crawler_name" {
  name        = "/noaa/glue/crawler_name"
  description = "The Name for the NOAA Glue Job"
  type        = "String"
  value       = aws_glue_crawler.noaa_parquet_crawler.name
}

resource "aws_ssm_parameter" "state_machine_arn" {
  name        = "/noaa/step_functions/noaa_machine"
  description = "The ARN for the step function in NOAA"
  type        = "String"
  value       = module.orchestration.pipeline_arn
}